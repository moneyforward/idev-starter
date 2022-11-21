#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TELEPRESENCE=$(command -v telepresence)
TELEPRESENCE_VERSION=2.8.5

# version compare
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

CURRENT_TELEPRESENCE_CLI_VERSION=$(telepresence version | grep "Client:" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/')
  vercomp $CURRENT_TELEPRESENCE_CLI_VERSION $TELEPRESENCE_VERSION
    case $? in
        2)
          echo -e "${RED}Alert! Your current Telepresence version is v$CURRENT_TELEPRESENCE_CLI_VERSION lower than v$TELEPRESENCE_VERSION ${NC}"
          echo -e "${RED}Please run: ${GREEN}make idev-install${NC} again!"
          exit 0
    esac

exit 1
