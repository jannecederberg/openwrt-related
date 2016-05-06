#!/usr/bin/env python2

"""
Script for reading memory contents from an embedded device with U-Boot as its bootloader.
The data is read over a USB-to-serial cable and saved into a binary file.
The script must be run as root (at least on Ubuntu) for sufficient serial connection permissions.

Author  Janne Cederberg
Date    2015-07-24
License MIT
"""

import binascii, re, serial, sys

# check correct amount of command-line arguments
if len(sys.argv) != 4:
    print "\nUsage: %s offset readlen target\n" % sys.argv[0]
    print "  offset    Memory offset to read from; always interpreted as hex string."
    print "  readlen   Number of bytes to read starting from offset."
    print "            Must be base10 or base16; indicate base16 with 0x prefix."
    print "  target    Filename for storing returned binary output.\n"
    exit(1)

# Command-line arguments and their validation
try:
    offset  = sys.argv[1]
    readlen = sys.argv[2] if sys.argv[2][0:2] == '0x' else hex(int(sys.argv[2]))
    target  = sys.argv[3]
except ValueError:
    print "Read length (%s) has to be an integer in either base10 or base16; indicate base16 with 0x prefix." % readlen

if len(offset) != 8 and len(offset) != 10:
    print "Memory offset (%s) has to be an 8-digit long hex string with or without hex-notation (0x1234abcd or 1234abcd)" % offset
    exit(2)
else:
    try:
        int(offset, 16)
    except ValueError:
        print "The given memory offset (%s) is not a valid hexadecimal number!" % offset
        exit(3)



# Open serial connection
ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)

ser.write('md.b %s %s\n' % (offset, readlen))
lines = ser.readlines()
ser.close()

f = open(target, 'w')
strip_hexdump_end_regex = re.compile(r'    [^\n]{1,17}\n$')

for line in lines[1:-1]:
    # Returned lines are of the following hexdump format:
    # offset  : (string representation of 16 byte values)          (ASCII representation of the bytes)
    # 01234567: 10 00 00 ff 00 00 00 00 10 00 00 fd 00 00 00 00    ................\n

    # Remove hexdump offset notation ("1234abcd: ") from the beginning of each line
    line = line[10:]

    # Remove ASCII representation of hexdump at end of lines
    line = strip_hexdump_end_regex.sub('', line)
    
    # Remove spaces from between string representations of bytes
    line = line.replace(' ', '')

    #print line

    # Convert string representation of binary data to binary
    f.write(binascii.unhexlify(line))
f.close()