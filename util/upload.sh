#!/bin/sh

SERIALPORT=${1:-"/dev/cu.usbserial"}
LUATOOL="python ./util/luatool/luatool/luatool.py -p $SERIALPORT -b 115200 --delay 0.05"

echo $'\nHi!'
echo "This will wipe the entire flash memory..."
echo "And upload/compile all the µS source into the ESP8266."

read -p $'Press any key to continue...\n\n'

#Wipe
$LUATOOL -w

#Static files
$LUATOOL -f lib.js
$LUATOOL -f screen.css
$LUATOOL -f setup.html
$LUATOOL -f setup.js
$LUATOOL -f main.html
$LUATOOL -f main.js

#App code
$LUATOOL -f configure.lua -c
$LUATOOL -f logger.lua -c
$LUATOOL -f server.lua -c
$LUATOOL -f setup.lua -c
$LUATOOL -f main.lua -c
$LUATOOL -f backend.lua -c
$LUATOOL -f init.lua -r

echo $'\nI\'m done here. Thank you!\n'
