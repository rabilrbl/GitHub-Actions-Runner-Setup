#!/bin/bash

# This script checks if jq is installed and if not, installs it using the respective distro package manager

# define distro variables 
debian="debian"
ubuntu="ubuntu"
fedora="fedora"
centos="centos"
redhat="redhat"

# detect the distro
distro=`cat /etc/os-release | grep -w ID | cut -d\" -f2`

# check if jq is installed
jq --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
     echo -e "jq is already installed!\n"
else
    echo -e "jq is not installed. Installing now...\n"
    # install jq according to the distro
    case $distro in
        $debian|$ubuntu) sudo apt-get install -y jq ;;
        $fedora|$centos|$redhat) sudo yum install -y jq ;;
    esac
fi

# This script will setup a self-hosted GitHub Actions runner

if [ "$#" -ne 4 ]; then
    echo "Error: GITHUB_TOKEN and USERNAME required"
    echo "Usage: "
    echo "--github-token or -gt : Token provided by github when registering for actions"
    echo "--username or -u : GitHub username or organization username"
    echo "./install.sh --github-token <GITHUB_TOKEN> --username <USERNAME>"
    exit 1
fi
 
while [ "$1" != "" ]; do
    case $1 in
        -gt | --github-token )  shift
                                GITHUB_TOKEN=$1
                                ;;
        -u | --username )   shift
                                USERNAME=$1
                                ;;
    esac
    shift
done

# Detect the linux distro and use respective package manager to install git
if [ -f /etc/redhat-release ] ; then
  sudo yum install -y git
elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
  sudo apt-get install -y git
elif [ -f /etc/fedora-release ]; then
  sudo dnf install -y git
else
  echo "This script only works on Redhat, Debian, Ubuntu and Fedora based systems"
  exit 1
fi

# Create a directory for the runner
echo "Creating directory for the runner"
mkdir -p ~/actions-runners
cd ~/actions-runners

# Download the latest GitHub Actions runner
echo "Downloading the latest GitHub Actions runner"
wget $(curl -Ls https://api.github.com/repos/actions/runner/releases/latest | jq -r '.assets[].browser_download_url' | grep -E "actions-runner-linux-x64-[0-9.]+tar.gz")

# Extract the runner archive
echo "Extracting the runner archive"
tar xzf ./actions-runner-linux-x64-*.tar.gz

# Enter the extracted directory
echo "Entering the extracted directory"
cd ./actions-runner-*-linux-x64

# Configure the runner
echo "Configuring the runner"
./config.sh --url https://github.com/$USERNAME --token $GITHUB_TOKEN

# Start the runner
echo "Starting the runner"
sudo nohup ./run.sh >> runner.log &

