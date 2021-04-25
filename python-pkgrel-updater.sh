#!/usr/bin/env bash

set -Eeuo pipefail


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

cd ${args[@]}

pacman -Fqx "/python3.8/" | grep 'mingw64/' | cut -f2- -d/ | \
	cut --complement -f3 -d- | while read -r dir; do
	if [ -d "$dir" ]; then
		echo "Updating pkgrel for $dir"
		cd "$dir"
		awk -F"=" 'BEGIN{OFS="="} { if ($1=="pkgrel") {print $1,$2=$2+1} else {print $0}}' \
		PKGBUILD > temp && mv temp PKGBUILD
		cd ..

	else 
		echo "$dir does not exist"
	fi
done

