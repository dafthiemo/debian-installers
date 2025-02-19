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

#
# https://packages.debian.org/en/trixie/ca-certificates
# https://packages.debian.org/en/trixie/gnupg
installPackage ca-certificates gnupg

# Add docker repository
# first add Docker’s GPG key via following curl command.

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

updatePackagesInformations
sudo apt-get -qq install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl stop docker
sudo systemctl start docker

sudo apt-get -qq autoremove

magentaMsg "Do not forget to Allow Users to Run Docker Command"
magentaMsg "By adding them to doker group"
magentaMsg "- sudo usermod -aG docker <user>"
magentaMsg "- newgrp docker"
greenMsg "----------"

greenMsg "Install is complete."
greenMsg "THE END!"

# Removal of Docker
# sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras -y
# sudo rm -rf /var/lib/docker
# sudo rm -rf /var/lib/containerd