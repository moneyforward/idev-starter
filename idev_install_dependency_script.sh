#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DOCKER=$(command -v docker)
DOCKER_COMPOSE=$(command -v docker-compose)
AWS=$(command -v aws)
AWS_VERSION=2.7.15

KUBECTL=$(command -v kubectl)
KUBECTL_VERSION=1.24.0

TELEPRESENCE=$(command -v telepresence)
TELEPRESENCE_VERSION=2.8.5
CHIP=$(uname -m)

AWS_PROFILE=idev

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

_install_aws() {
  echo -e "${GREEN}Aws cli is not available. ====> Install aws-cli}${NC}"
	curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
	sudo installer -pkg AWSCLIV2.pkg -target /
	rm AWSCLIV2.pkg
}

_install_telepresence() {
  if [ "$CHIP" = "arm64" ];
  then
    echo -e "${GREEN}Install Telepresence v${TELEPRESENCE_VERSION}${NC}"
    sudo curl -fL https://app.getambassador.io/download/tel2/darwin/arm64/${TELEPRESENCE_VERSION}/telepresence -o /usr/local/bin/telepresence
  else
    sudo curl -fL https://app.getambassador.io/download/tel2/darwin/amd64/${TELEPRESENCE_VERSION}/telepresence -o /usr/local/bin/telepresence
  fi

  sudo chmod a+x /usr/local/bin/telepresence
}

if [ "" = "$DOCKER" ];
then
	echo "docker is not available. Install by following https://docs.docker.com/desktop/mac/install/"
	exit 1
fi
if [ "" = "$DOCKER_COMPOSE" ];
then
	echo "docker-compose is not available.  Install by following https://docs.docker.com/desktop/mac/install/"
	exit 1
fi
if [ "" = "$TELEPRESENCE" ];
then
  _install_telepresence
else
  telepresence quit -ur
  # cut correctly number of version when run telepresence version command
  CURRENT_TELEPRESENCE_CLI_VERSION=$(telepresence version | grep "Client:" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/')
  vercomp $CURRENT_TELEPRESENCE_CLI_VERSION $TELEPRESENCE_VERSION
    case $? in
        2)
          echo -e "${RED}Alert! Your current Telepresence version lower than v$TELEPRESENCE_VERSION ${NC}"
          read -p "Do you want install Telepresence v$TELEPRESENCE_VERSION [y/N]: " IS_WANT_INSTALL_TELEPRESENCE;
          if [ "y" = "$IS_WANT_INSTALL_TELEPRESENCE" ]; then
            # Remove old telepresence old version
            sudo rm -rf /usr/local/bin/telepresence
            _install_telepresence
          fi
    esac
fi
if [ "" = "$AWS" ];
then
	_install_aws
else
  # if version lower than AWS_VERSION user can choice to install new version
  CURRENT_AWS_CLI_VERSION=$(aws --version 2>&1 | cut -d " " -f1 | cut -d "/" -f2)
  vercomp $CURRENT_AWS_CLI_VERSION $AWS_VERSION
    case $? in
        2)
          echo -e "${RED}Alert! Your current aws version lower than v$AWS_VERSION${NC}"
          read -p "Do you want install aws v$AWS_VERSION [y/N]: " IS_WANT_INSTALL_AWS;
          if [ "y" = "$IS_WANT_INSTALL_AWS" ]; then
            _install_aws
          fi
    esac
fi
if [ "" = "$KUBECTL" ];
then
  echo -e "${GREEN}kubectl is not available. ====> Install kubectl${KUBECTL_VERSION}${NC}"
  if [ "$CHIP" = "arm64" ];
  then
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/darwin/arm64/kubectl";
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/darwin/arm64/kubectl.sha256";
  else
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/darwin/amd64/kubectl";
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/darwin/amd64/kubectl.sha256";
  fi
	echo "$(shell cat kubectl.sha256)  kubectl" | shasum -a 256 --check; \
	chmod +x ./kubectl; \
	sudo mv ./kubectl /usr/local/bin/kubectl; \
	sudo chown root: /usr/local/bin/kubectl; \
	rm kubectl.sha256;
fi

echo "docker, docker-compose, aws, kubectl already installed"
# check aws profile if it already exists
profile_status=$( (aws configure --profile ${AWS_PROFILE} list ) 2>&1 )
if [[ $profile_status = *'could not be found'* ]]; then
  echo -e "${GREEN}##############################################"
  echo -e "# Please take a look at how to aws sso login"
  echo -e "# https://github.com/moneyforward/developer-platform-service-k8s/wiki/%5BProcedure%5D-idev-cluster-connection-procedure#log-in-with-aws_sso"
  echo -e "#"
  echo -e "#"
  echo -e "# Please select aws account ${RED}DEVELOPER-PLATFORM${NC}"
  echo -e "${GREEN}##############################################${NC}"

  aws configure sso --profile ${AWS_PROFILE}
fi
