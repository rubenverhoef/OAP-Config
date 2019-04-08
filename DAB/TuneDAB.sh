#!/bin/bash

sudo /opt/OAP/radio_cli -c $1 -e $2 -f $3 -p
arecord -D hw:0 -c 2 -r 48000 -f S16_LE -q | aplay -D hw:1 -c 2 -q &

exit 0
