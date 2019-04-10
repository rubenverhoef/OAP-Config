#!/bin/bash

gpio -g mode 13 up

SINK=$(runuser -l pi -c "pactl list short sources | grep 'alsa_output.usb'")
SINK=$(echo $SINK | awk '{ print $1 }')
AUX=$(runuser -l pi -c "pactl list short sources | grep 'alsa_input.usb'")
AUX=$(echo $AUX | awk '{ print $1 }')

AUX_STATE=0
MODULE_ID=0

while true; do
    IGNITION_GPIO=`gpio -g read 13`
    AUX_GPIO=`gpio -g read 22`
    if [ $IGNITION_GPIO -ne 0 ] ; then
        if [ ! -f /tmp/android_device ] && [ ! -f /tmp/btdevice ]; then
            sudo shutdown -h now
        fi
    fi
    if [ $AUX_GPIO -ne 0 ] && [$AUX_STATE -ne 1]; then
        AUX_STATE=1
        MODULE_ID=$(runuser -l pi -c "pactl load-module module-loopback source=$AUX sink=$SINK")
    elif [ $AUX_GPIO -ne 1 ] && [$AUX_STATE -ne 0]; then
        AUX_STATE=0
        runuser -l pi -c "pactl unload-module $MODULE_ID"
    fi
    sleep 1
done

exit 0
