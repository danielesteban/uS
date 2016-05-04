#!/bin/sh

SERIALPORT=${1:-"/dev/cu.usbserial"}
LUATOOL="python ./util/luatool/luatool/luatool.py -p $SERIALPORT -b 115200 --delay 0.15"

echo $'\nHi!'
echo "This will wipe the entire flash memory..."
echo "And upload/compile all the µS source into the ESP8266."

read -p $'Press any key to continue...\n\n'

#Wipe
$LUATOOL -w

#Static files
if [ -d "util/build/" ]; then
	STATIC="util/build/"
fi
$LUATOOL -f ${STATIC}lib.js
$LUATOOL -f ${STATIC}screen.css
$LUATOOL -f ${STATIC}setup.html
$LUATOOL -f ${STATIC}setup.js
$LUATOOL -f ${STATIC}main.html
$LUATOOL -f ${STATIC}main.js

#App code
$LUATOOL -f configure.lua -c
$LUATOOL -f logger.lua -c
$LUATOOL -f server.lua -c
$LUATOOL -f setup.lua -c
$LUATOOL -f main.lua -c
$LUATOOL -f backend.lua -c
$LUATOOL -f timetable.lua -c
$LUATOOL -f init.lua -r

echo $'\nI\'m done here. Thank you!\n'
