#!/usr/bin/env bash
set -euo pipefail

# Versioning follows this strategy:
# An annotated tag is used to construct the start of the semantic version, and then appending the jenkins build number
# We can easily trace software deployments using this method.
# i.e. 1.2.3-4-5 (whereby 1 is the major release, 2 is the minor release, 3 is the path,
# 4 is the commit number, and 5 is the jenkins build number)

function build_version () {
  local GIT_VERSION
  GIT_VERSION=$(git describe --long | sed 's/-g[A-Fa-f0-9]*$//')
  local JENKINS_BUILD_NUMBER="${BUILD_NUMBER:-0}"
  local VERSION="${GIT_VERSION}-${JENKINS_BUILD_NUMBER}"

  echo "${VERSION}"
}

function package_artifact_zip () {
  local PACKAGE_NAME=${1}
  local VERSION=${2}
  # bash doesn't treat arrays as an object when passing to functions, so pop the first two values from
  # the stack using shift, and reference the rest as an array. Should use a "real" programming language if this
  # script is to be used elsewhere
  shift
  shift
  local PACKAGE_CONTENTS=(${@})

  zip -qr --exclude=*.git* --exclude=ci/* "${PACKAGE_NAME}-${VERSION}.zip" "${PACKAGE_CONTENTS[@]// }"
}

function print_help () {
  echo -e "Lambda Package Management"
  echo -e "Usage: \n"
  echo -e "-c \tPackage contents, eg: -c file1 -c file2"
  echo -e "-p \tPackage name"
  echo -e "-s \tS3 bucket, eg: s3://test-bucket/"
  echo -e "-v \tPackage version"
}

function main() {
  local PACKAGE_CONTENTS
  local PACKAGE_NAME
  local VERSION
  local S3_BUCKET
  local OPTIND

  while getopts ":hc:p:v:" OPT ; do
    case "${OPT}" in
      c ) # package contents
        local c+=("${OPTARG}")
        ;;
      p ) # package name
        local p="${OPTARG}"
        ;;
      v ) # set version
        local v="${OPTARG}"
        ;;
      h ) # prints help function
        print_help
        ;;
      ? ) # prints help function and set exit status
        echo "Unsupported argument: -${OPTARG}" >&2
        print_help
        exit 1
        ;;
      : )
        echo "Option -${OPTARG} requires an argument" >&2
        exit 1
        ;;
    esac
  done
  shift $((OPTIND-1))

  if [[ -z "${c[*]+x}" ]]; then
    echo "Specify package contents"
    print_help
    exit 1
  else
   PACKAGE_CONTENTS=("${c[@]}")
  fi

  if [[ -z "${p+x}" ]]; then
    PACKAGE_NAME=${BUILD_NAME:-"test_build"}
  else
    PACKAGE_NAME=${p}
  fi

  if [[ -z "${v+x}" ]]; then
    VERSION=$(build_version)
  else
    VERSION=${v}
  fi

  echo -e "Packaging: ${PACKAGE_NAME}-${VERSION}.zip with content: ${PACKAGE_CONTENTS[*]}"
  package_artifact_zip "${PACKAGE_NAME}" "${VERSION}" "${PACKAGE_CONTENTS[@]}"
}

main "$@"
