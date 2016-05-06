#!/usr/bin/expect


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
# 6. Run flash-uboot.sh as sudo.
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


set timeout 120

expect "Autobooting in 1 seconds"
send "tpl\n"
expect "db12x>"
send "tftp 0x80060000 uboot.bin\n"
expect "Bytes transferred"
expect "db12x>"
send "erase 0x9f000000 +0x20000; cp.b 0x80060000 0x9f000000 0x20000\n"
expect "done"
expect "db12x>"
close



# =======================================
# U-BOOT_MOD printenv on TP-Link WDR4300
# =======================================

#bootargs=console=ttyS0,115200 root=31:02 rootfstype=squashfs init=/sbin/init mtdparts=ath-nor0:256k(u-boot),64k(u-boot-env),6336k(rootfs),1408k(uImage),64k(mib0),64k(ART)
#bootcmd=bootm 0x9F020000
#bootdelay=1
#baudrate=115200
#ipaddr=192.168.1.1
#serverip=192.168.1.2
#bootfile="firmware.bin"
#loadaddr=0x80800000
#ncport=6666
#uboot_addr=0x9F000000
#uboot_name=uboot.bin
#uboot_size=0x1EC00
#uboot_backup_size=0x20000
#uboot_upg=if ping $serverip; then mw.b $loadaddr 0xFF $uboot_backup_size && cp.b $uboot_addr $loadaddr $uboot_backup_size && tftp $loadaddr $uboot_name && if itest.l $filesize <= $uboot_size; then erase $uboot_addr +$uboot_backup_size && cp.b $loadaddr $uboot_addr $uboot_backup_size && echo OK!; else echo ERROR! Wrong file size!; fi; else echo ERROR! Server not reachable!; fi
#firmware_addr=0x9F020000
#firmware_name=firmware.bin
#firmware_upg=if ping $serverip; then tftp $loadaddr $firmware_name && erase $firmware_addr +$filesize && cp.b $loadaddr $firmware_addr $filesize && echo OK!; else echo ERROR! Server not reachable!; fi
#ethact=eth0
#stdin=serial
#stdout=serial
#stderr=serial