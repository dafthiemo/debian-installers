#!/usr/bin/env bash

#
#          -e option: Will cause a bash script to exit immediately when a command fails.
#
#          -E option: Traps are pieces of code that fire when a bash script catches certain signals.
#                     Traps can also be used to catch special bash signals like EXIT, DEBUG, RETURN, and ERR.
#                     Using -e without -E will cause an ERR trap to not fire in certain scenarios.
#
# -o pipefail option: The bash shell normally only looks at the exit code of the last command of a pipeline.
#                     This behavior is not ideal as it causes the -e option to only be able to act on
#                     the exit code of a pipeline’s last command.
#                     (foo | echo "a" --> foo will be in error but not echo "a") ==> no error as the last command of | is OK
#                     This is where -o pipefail comes in. This particular option sets the exit code of a pipeline
#                     to that of the rightmost command to exit with a non-zero status, or to zero if all commands
#                     of the pipeline exit successfully.
#
#          -u option: Will causes the bash shell to treat unset variables as an error and exit immediately.
#                     Unset variables are a common cause of bugs in shell scripts, so having unset variables
#                     cause an immediate exit is often highly desirable behavior.
#
# For details (https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/)
#
set -Eeuo pipefail

SCRIPT_NAME="$(readlink -f "$0")"
SCRIPT_DIR="${SCRIPT_NAME%/*}"

source ${SCRIPT_DIR}/common.sh

trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

####
#-- MAIN
####

# script logic here
updatePackagesInformations

# Install packages after installing base Debian with no GUI

# Browsers Installation
installPackage firefox-esr
magentaMsg "Download and install google-chrome-stable"
installPackageAfterDownload "https://dl.google.com/linux/direct/" "google-chrome-stable_current_amd64.deb"

# Sound packages (pulseaudio installed prior)
installPackage alsa-utils volumeicon-alsa

# Neofetch/HTOP/TLDR
installPackage neofetch htop tldr

# EXA installation
# Add the following alias to replace ls command in .bashrc or .zshrc
# alias ls='exa -al --long --header --color=always --group-directories-first' 
#installPackage exa

installPackage fonts-powerline fonts-ubuntu fonts-liberation2 fonts-liberation

installPackage zsh unzip git-lfs graphviz

installPackage vim

installPackage curl jq

installPackage maven gradle

# tilix terminal emulator
installPackage tilix

# neovim telescope
installPackage ripgrep fd-find

sudo apt-get -qq autoremove

magentaMsg "Download jetbrains-toolbox."
downloadResource "https://download.jetbrains.com/toolbox" "jetbrains-toolbox-2.1.3.18901.tar.gz"

greenMsg "Install is complete."
greenMsg "THE END!"

