#!/bin/bash


# =============================================================================
#                            U-Boot flasher
# =============================================================================
#
# USE AT YOUR OWN RISK!
#
# This script is intended for updating U-Boot on TP-Link WDR4300 devices.
# Might work on other devices but no guarantees of such and if you're not
# careful you might brick your device. Be warned.
#
# This script requires expect to be installed.
#
# 0. Make a backup of U-Boot by doing the following:
#    - Start OpenWrt and run on the device: cat /dev/mtd0 > /tmp/uboot.bak.bin
#    - Save the created file to your computer for example using SCP.
# 1. Open the case of your your [WDR4300](https://wiki.openwrt.org/toh/tp-link/tl-wdr4300)
#    and connect your USB-UART cable to the device. (Device should be powered off)
# 2. Set up a TFTP server on your machine.
#    I've used ATFTP from the Ubuntu repositories.
# 3. Compile/obtain the U-Boot image you want to use.
#    The motivation for this script was flashing https://github.com/pepe2k/u-boot_mod
#    which adds an HTTP server on U-Boot level so that soft-brick situations
#    are simple to recover from without a serial cable.
# 4. Save the U-Boot image as uboot.bin in your TFTP server's root (e.g. /srv/tftp)
# 5. Connect an ethernet cable from one of the LAN ports to your computer.
# 6. Run this script as sudo.
# 7. Power on the WDR4300. Script will run and flash U-Boot.
# 8. This script might reset the MAC address on your device. Use the
#    U-Boot command `setmac` to set (and save) your MAC address after using this
#    script.
#
# =============================================================================
#
# Author:  Janne Cederberg
# GitHub:  github.com/jannecederberg
# License: MIT
#
# =============================================================================


# Set ttyUSB0 settings
#  - "115200"  : baud speed
#  - "cs8"     : 8 data bits
#  - "-cstopb" : one stop bit
#  - "-parenb" : no parity
#  - "-ixon"   : no flow control
sudo stty -F /dev/ttyUSB0 115200 cs8 -cstopb -parenb -ixon

# Control u-boot with expect
sudo cat /dev/ttyUSB0 | ./flash-uboot_sub.sh | sudo tee /dev/ttyUSB0