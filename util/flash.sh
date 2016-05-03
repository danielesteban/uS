#!/bin/sh

SERIALPORT=${1:-"/dev/cu.usbserial"}
ESPTOOL="python ./util/esptool/esptool.py --port $SERIALPORT"

echo $'\nHi!'
echo "Connect the GPIO0 of the ESP8266 to ground..."
echo "Reset It..."

read -p $'And press any key to continue...\n\n'

$ESPTOOL write_flash --verify 0x00000 ./util/firmware.bin

echo $'\nI\'m done here. Thank you!\n'
