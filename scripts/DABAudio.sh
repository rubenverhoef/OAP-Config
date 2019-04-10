#!/bin/bash

SINK=$(runuser -l pi -c "pactl list short sources | grep 'alsa_output.usb'")
SINK=$(echo $SINK | awk '{ print $1 }')
DAB=$(runuser -l pi -c "pactl list short sources | grep 'alsa_input.platform-soc'")
DAB=$(echo $DAB | awk '{ print $1 }')

sudo /opt/OAP/radio_cli -b D -o 1

runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=$SINK"

exit 0
