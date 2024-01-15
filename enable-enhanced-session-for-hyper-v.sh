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

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# script logic here
updatePackagesInformations

if [ -f /var/run/reboot-required ]; then
    redMsg "A reboot is required in order to proceed with the install."
    redMsg "Please reboot and re-run this script to finish the install."
    exit 1
fi

###############################################################################
# XRDP
#

# https://packages.debian.org/trixie/linux-perf
installPackage linux-perf

# Install the xrdp service so we have the auto start behavior
installPackage xrdp

systemctlStop xrdp.service
systemctlStop xrdp-sesman.service

# Configure the installed XRDP ini files.
# use vsock transport.
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Add script to setup the debian session properly
if [ ! -e /etc/xrdp/startdebian.sh ]; then
cat >> /etc/xrdp/startdebian.sh << EOF
#!/bin/sh
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/startdebian.sh
fi

# use the script to setup the debian session
sed -i_orig -e 's/startwm/startdebian/g' /etc/xrdp/sesman.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
if [ ! -e /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf ]; then
  echo "blacklist vmw_vsock_vmci_transport" > /etc/modprobe.d/blacklist-vmw_vsock_vmci_transport.conf
fi

#Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
  echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
[ -d /etc/polkit-1/localauthority/50-local.d ] || mkdir -p /etc/polkit-1/localauthority/50-local.d

cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# reconfigure the service
systemctl -q daemon-reload
systemctlStart xrdp.service

#
# End XRDP
###############################################################################

greenMsg "Install is complete."
greenMsg "THE END!"
blueMsg "Reboot your machine to begin using XRDP."