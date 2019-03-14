#!/bin/bash

# check gpio pin if activated
gpio -g mode 13 up
while true; do
    IGNITION_GPIO=`gpio -g read 13`
    if [ $IGNITION_GPIO -ne 0 ] ; then
        if [ ! -f /tmp/android_device ] && [ ! -f /tmp/btdevice ]; then
            sudo shutdown -h now
        fi
    fi
    sleep 1
done

exit 0
