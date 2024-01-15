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

# Install those packages after installing base Debian with no GUI

# Xorg the default X Window server since Debian 4.0
# For more details see: https://wiki.debian.org/Xorg
#
# and some xtools
# https://packages.debian.org/trixie/xvkbd
# https://packages.debian.org/trixie/xbindkeys
# https://packages.debian.org/trixie/xbacklight
installPackage xorg xbacklight xbindkeys xvkbd

# Build-essential.
# The build-essentials packages are meta-packages that are necessary for compiling software.
# They include the GNU debugger, g++/GNU compiler collection, and some more tools and
# libraries that are required to compile a program
installPackage build-essential

# Microcode for Intel/AMD
# A microcode is nothing but CPU firmware provided by Intel or AMD.
# The Linux kernel can update the CPU’s firmware without the BIOS update at boot time.
# For more details see: https://www.cyberciti.biz/faq/install-update-intel-microcode-firmware-linux
installPackage intel-microcode

# Cinnamon Desktop environment
# https://projects.linuxmint.com/cinnamon/
installPackage cinnamon

# https://packages.debian.org/trixie/dialog
# https://packages.debian.org/trixie/mtools
installPackage dialog mtools

# Attempts to replicate the functionality of the 'old' apm command
# on ACPI systems, including battery and thermal information
# https://packages.debian.org/trixie/acpi
#
# Modern computers support the Advanced Configuration and Power Interface (ACPI) to allow
# intelligent power management on your system and to query battery and configuration status.
# https://packages.debian.org/trixie/acpid
#
# https://packages.debian.org/trixie/gvfs-backends
installPackage acpi acpid gvfs-backends

# Avahi is a fully LGPL framework for Multicast DNS Service Discovery.
# It allows programs to publish and discover services and hosts
# running on a local network with no specific configuration.
# https://packages.debian.org/en/trixie/avahi-daemon
installPackage avahi-daemon

systemctlEnable avahi-daemon
systemctlEnable acpid

# Simple display manager
# Install LightDM + GTK Greeter + Settings
# https://packages.debian.org/en/trixie/lightdm
# https://packages.debian.org/en/trixie/lightdm-gtk-greeter
# https://packages.debian.org/en/trixie/lightdm-gtk-greeter-settings
installPackage lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

systemctlEnable lightdm

sudo apt autoremove -qq

greenMsg "Install is complete."
greenMsg "THE END!"
blueMsg "Reboot your machine to begin using Cinnamone."
