#!/bin/bash
#    _____                  __
#   / ___/____  ____ ______/ /__
#   \__ \/ __ \/ __ `/ ___/ //_/
#  ___/ / /_/ / /_/ / /  / ,<
# /____/ .___/\__,_/_/  /_/|_|
#     /_/ v 1.2.0
#
# Copyright (c) 2021 ChecksumDev.
# Licensed under the GNU GPLv3.

# globals
COUNT=0
VERSION=1.2.0
DISTRO=$(lsb_release -sc)
MIRRORS="$(wget -qO - mirrors.ubuntu.com/mirrors.txt)"

# colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo -e "$RED> You must be root to run this script, please use root to generate the mirrors."
    exit 1
fi

# check if apt is installed
if [ ! -f /usr/bin/apt ]; then
    echo -e "$RED> This distribution is not supported by this script."
    exit 1
fi

# check if there is an internet connection
if [ -z "$(ping -c 1 -W 1 1.1.1.1)" ]; then
    echo -e "$RED> No internet connection detected, please connect to the internet and run this script again$NC"
    exit 1
fi

# check if curl is installed
if [ ! -f /usr/bin/curl ]; then
    echo "curl is not installed, installing.."
    apt-get install curl -y
    if [ $? -ne 0 ]; then
        echo -e "$RED> curl failed to install, please install curl and run this script again."
        exit 1
    fi
fi

# check if wget is installed
if [ ! -x "$(command -v wget)" ]; then
    # install wget
    echo -e "$YELLOW> Installing wget$NC"
    apt-get install -y wget
    if [ $? -ne 0 ]; then
        echo "$RED> wget failed to install, please install wget and run this script again$NC"
        exit 1
    fi
fi

echo -e "$YELLOW   _____                  __  "
echo -e "$YELLOW  / ___/____  ____ ______/ /__"
echo -e "$YELLOW  \__ \/ __ \/ __ / ___/ / /_/"
echo -e "$YELLOW  ___/ / /_/ / /_/ / /  / \`,<"
echo -e "$YELLOW /____/ .___/\__,_/_/  /_/|_|"
echo -e "$YELLOW     /_/ Running spark.sh (v$VERSION)$NC"
echo -e "$NC"

# if spark is out of date, update it via github
if [ "$(curl -s https://api.github.com/repos/ChecksumDev/spark/releases/latest | grep 'tag_name' | cut -d '"' -f 4)" != "$VERSION" ]; then
    # update the script by downloading the latest version
    echo -e "$YELLOW> spark.sh is out of date, updating...$NC"
    curl -s https://api.github.com/repos/ChecksumDev/spark/releases/latest | grep 'browser_download_url' | cut -d '"' -f 4 | xargs -I {} curl -L {} -o spark.sh
    chmod +x spark.sh

    echo -e "$YELLOW> Done updating, restarting the process!$NC"
    bash spark.sh "$1"

    exit 0
fi

# skip startup prompt when the noprompt bash option is set
if [[ "$1" = "--noprompt" ]]; then
    echo "" >>/dev/null
else
    echo -e "$YELLOW> This script will generate ~15 mirrors for $DISTRO and backup the existing /etc/apt/sources.list file.$NC"
    echo -e -n "$YELLOW> Do you want to continue? [y/n] $YELLOW"
    read -r continue
    if [ "$continue" != "y" ]; then
        echo -e "$NC"
        exit 1
    fi
fi

# backup any existing sources.list file
echo -e "$YELLOW> Backing up any existing /etc/apt/sources.list ->/etc/apt/sources.list.spark.bak$NC"
if [ -f /etc/apt/sources.list ]; then
    mv /etc/apt/sources.list /etc/apt/sources.list.bak
fi

{
    echo "#   _____                  __  "
    echo "#  / ___/____  ____ ______/ /__"
    echo "#  \__ \/ __ \/ __ / ___/ / /_/"
    echo -e "#  ___/ / /_/ / /_/ / /  / \`,<"
    echo "# /____/ .___/\__,_/_/  /_/|_|"
    echo -e "#     /_/" "v $VERSION"
    echo "#"
    echo "# This sources.list was generated by spark.sh!"
    echo "# Check us out on https://github.com/ChecksumDev/spark"
    echo ""
} >>/etc/apt/sources.list

echo -e "$YELLOW> Generating mirror list...$NC"

for i in $MIRRORS; do
    DOMAIN=$(echo "$i" | cut -d'/' -f3)

    # check if the mirror is available via pinging the domain.
    if [ -z "$(ping -c 1 -W 1 "$DOMAIN")" ] >>/dev/null; then
        echo -e "$RED > Mirror $DOMAIN is not available$NC"
        count=$((count + 1))
        continue
    fi

    # stop after the first 15 mirrors
    if [ $((++max)) -gt $((COUNT + 15)) ]; then
        break
    fi

    echo "deb $i $DISTRO main restricted universe multiverse" >>/etc/apt/sources.list
    echo -e "$YELLOW> The mirror $DOMAIN was added to /etc/apt/sources.list$NC"
done

echo -e "$NC"
echo -e "$YELLOW> Success!$NC"
