#!/bin/bash

sudo /opt/OAP/radio_cli -b D -o 1
arecord -D hw:0 -c 2 -r 48000 -f S16_LE -q | aplay -D hw:1 -c 2 -q &

exit 0
