#!/bin/bash


# =============================================================================
#                          OpenWrt remote flasher
# =============================================================================
#
# This script is intended for automated the flashing of a new/different build
# of OpenWrt onto a working version of OpenWrt. This script in itself is not
# device-dependent but of course the firmware image you want to flash has to
# be for the device(s) you're about to flash.
#
# Currently this script assumes you're connected to the device to be flashed
# over ethernet from the machine running this script. That can of course
# be changed though to taking the TARGET's IP or domain via
# command-line parameters. Making such a change would enable running this
# script based on a list of target machines for example in order to flash
# multiple devices remotely. Script currently assumes IPv6 addresses! If you
# use IPv4, then remove the -6 parameter on nmap and scp.
#
# 1. The script first checks whether telnet is enabled on the target (OpenWrt
#    default after a new installation of prebuilt firmware) and if yes
#    will disable telnet by setting a password on root in order to enable SCP/SSH.
# 2. After that the script will add your SSH public key to the device for
#    smoother operation, SCP the firmware file to be flashed onto the device
#    and finally flash the device.
# 3. After the device has been flashed, this script will check whether telnet
#    is again enabled and if yes, disable it by setting a root password.
#
# =============================================================================
#
# Author:  Janne Cederberg
# GitHub:  github.com/jannecederberg
# License: MIT
#
# =============================================================================

INTERFACE=eth0
REMOTE_IPv6=$(ping6 ff02::1%eth0 | head -n 3 | tail -n 1 | grep -Po 'fe80::[0-9a-f:]+[0-9a-f]' )
TARGET=$REMOTE_IPv6%$INTERFACE
FLASH_IMAGE=wibed_tl-wdr4300_normal_v03.bin
REMOTE_PASSWORD=wibed

# Make sure expect is installed
if ! which expect &> /dev/null; then
	echo You need to install the expect command to be able to use this script
	exit 1
fi


# Remove possible previous known host to prevent hacking alert
# (after firmware flash or after changing device would be a problem otherwise)
ssh-keygen -R "$TARGET"


function disable_telnet_enable_ssh {
	if nmap -6 $TARGET | grep -o telnet &> /dev/null; then
	#if [ "$?" == "0" ]; then
		expect -c "
			spawn telnet $TARGET
			expect root
			send \"passwd\n\"
			expect \"New password: \"
			send \"$REMOTE_PASSWORD\n\"
			expect \"Retype password: \"
			send \"$REMOTE_PASSWORD\n\"
			expect root
			send \"exit\n\"
		"
	fi
}

disable_telnet_enable_ssh


# Copy SSH public key over when password auth is still in use.
# This is done to simplify the procedures that follow in later scripts.
expect -c "
	spawn scp -6 /home/$( whoami )/.ssh/id_rsa.pub root@\[$TARGET\]:/etc/dropbear/authorized_keys
	expect \"Are you sure you want to continue connecting (yes/no)?\"
	send \"yes\n\"
	expect {
		password: { send \"$REMOTE_PASSWORD\n\"; exp_continue }
		eof exit
	}
"

# Transfer firmware to device
scp -6 $FLASH_IMAGE root@[$TARGET]:/tmp

# Run the sysupgrade command without keeping old settings
ssh root@$TARGET "( sysupgrade -n /tmp/$FLASH_IMAGE &> /tmp/upgrade.log ) & exit"


# Wait until device starts rebooting
while(true); do
	if ! ping6 -c1 $TARGET &> /dev/null; then
		break
	fi
	clear
	echo Waiting for device to start rebooting...
	sleep 2
done

# Wait until device has booted and replies to ping again
while(true); do
	if ping6 -c1 $TARGET &> /dev/null; then
		break
	fi
	clear
	echo Device has now started rebooting. Waiting for it to respond to ping again...
	sleep 2
done

# Check if telnet is enabled; timeout if not
for i in $( seq 5 ); do
	if nmap -6 $TARGET | grep -o telnet &> /dev/null; then
		disable_telnet_enable_ssh
		break
	fi
	clear echo Waiting for telnet to be running...
	sleep 2
done

echo Flashing $TARGET done
