#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] FOLDERS

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 
      param="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ ${#args[@]} -eq 0 ]] && die "Missing script argument FOLDER"

  return 0
}

parse_params "$@"
setup_colors

echo "Pulling git master"
git checkout master
git pull upstream master

for d in ${args[@]}/ ; do
  echo "Checking version in ${d}" 
  cd ${d}
  PKG_NAME=$(sed '/^_realname=/!d; s/_realname=//' PKGBUILD)
  echo $PKG_NAME
  MINGW_VERSION=$(sed '/^pkgver=/!d; s/pkgver=//' PKGBUILD)
  echo $MINGW_VERSION
  LAST_VERSION=$(lastversion --at pip ${PKG_NAME})
  echo $LAST_VERSION
  if [ $MINGW_VERSION != $LAST_VERSION ];
  then
    sed -i "s/^pkgver=.*/pkgver=${LAST_VERSION}/g" PKGBUILD
    sed -i "s/^pkgrel=.*/pkgrel=1/g" PKGBUILD
    updpkgsums
    MINGW_INSTALLS=mingw64 makepkg-mingw -sLf
    git checkout -b ${PKG_NAME}-${LAST_VERSION}
    git add PKGBUILD
    git commit -m "Update ${PKG_NAME} to version ${LAST_VERSION}"
    git push -u origin ${PKG_NAME}-${LAST_VERSION}
    git checkout master
  fi
  cd ..
done
  
msg "${RED}Read parameters:${NOFORMAT}"
msg "- flag: ${flag}"
msg "- param: ${param}"
msg "- arguments: ${args[*]-}"
