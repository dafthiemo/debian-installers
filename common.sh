#!/usr/bin/env bash

# Formatting: (attr) in 0 1 2 4 5 7
# Background: (clbg) in {40..47} {100..107} 49
# Foreground: (clfg) in {30..37} {90..97} 39
# "\e[${attr};${clbg};${clfg}m"

NORMAL="\e[0;49;39m"
DEFAULT_COLOR="\e[1;49;39m"

#BLACK="\e[1;49;30m"
#LIGHT_GRAY="\e[1;49;37m"
#LIGHT_RED ="\e[1;49;91m"
#LIGHT_GREEN ="\e[1;49;92m"
#LIGHT_YELLOW ="\e[1;49;93m"
#LIGHT_BLUE ="\e[1;49;94m"
#LIGHT_MAGENTA ="\e[1;49;95m"
#LIGHT_CYAN ="\e[1;49;96m"
#WHITE="\e[1;49;97m"

msg() {
  printf "${NORMAL}%s\n" "${1-}"
}

redMsg() {
  RED="\e[1;49;31m"
  printf "${RED} %s ${NORMAL}\n" "${1-}"
}

greenMsg() {
  GREEN="\e[1;49;32m"
  printf "${GREEN} %s ${NORMAL}\n" "${1-}"
}

yellowMsg() {
  YELLOW="\e[1;49;33m"
  printf "${YELLOW} %s ${NORMAL}\n" "${1-}"
}

blueMsg() {
  BLUE="\e[1;49;34m"
  printf "${BLUE} %s ${NORMAL}\n" "${1-}"
}

magentaMsg() {
  MAGENTA="\e[1;49;35m"
  printf "${MAGENTA} %s ${NORMAL}\n" "${1-}"
}

cyanMsg() {
  CYAN="\e[1;49;36m"
  printf "${CYAN} %s ${NORMAL}\n" "${1-}"
}

darkGreyMsg() {
  DARK_GRAY="\e[1;49;90m"
  printf "${DARK_GRAY} %s ${NORMAL}\n" "${1-}"
}

updatePackagesInformations(){
  magentaMsg "Download and update package information from all configured sources"
  sudo apt-get -qq update
}

installPackage()
{
  for package in "$@"
  do
    if [[ $(sudo dpkg-query -W -f='${db:Status-Status}' ${package} 2>/dev/null) == "installed" ]]
    then
      redMsg "${package} is already installed."
    else
      greenMsg "Installing ${package} ... (Be Patient, it will probably takes time to install dependencies too ...)"
      sudo apt-get -qq install -y ${package}
    fi
  done
}

installPackageAfterDownload()
{
  resource_path=$1
  resource_name=$2

  actual_dir=`pwd`

  cd /tmp
  wget -q ${resource_path}/${resource_name}

  sudo dpkg-deb --info ${resource_name} &> /dev/null
  if [ $? -eq 0 ]
  then
    redMsg "${resource_name} is already installed."
  else
    greenMsg "Installing ${resource_name} ..."
    sudo apt-get -qq install -y /tmp/${resource_name}
  fi

  cd ${actual_dir}
  resource_path=""
  resource_name=""
}

downloadResource()
{
  resource_path=$1
  resource_name=$2

  actual_dir=`pwd`

  TOOLS_DIR="${HOME}/tools"
  [ -d ${TOOLS_DIR} ] || mkdir -p ${TOOLS_DIR}

  cd ${TOOLS_DIR}
  wget -q ${resource_path}/${resource_name}

  cd ${actual_dir}
  resource_path=""
  resource_name=""
}

installFont()
{
  font_name=$1

  VERSION="v3.1.1"
  GITHUB_RELEASES="https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}"

  resource_path=${GITHUB_RELEASES}
  resource_name=${font_name}.zip

	wget -q ${resource_path}/${resource_name}
	magentaMsg "Instaling font: ${font_name}"
	unzip -oqq ${resource_name} -d $HOME/.local/share/fonts/${font_name}/
	rm ${resource_name}
}

systemctlEnable()
{
  magentaMsg "Systemd enabling $1"
  sudo systemctl -q enable $1
}

systemctlStart()
{
  magentaMsg "Systemd starting $1"
  sudo systemctl -q start $1
}

systemctlStop()
{
  magentaMsg "Systemd stopping $1"
  sudo systemctl -q stop $1
}
