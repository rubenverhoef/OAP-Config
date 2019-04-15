#!/bin/bash

# Get audio output
SINK=$(runuser -l pi -c "pactl list short sources | grep 'alsa_output.usb'")
SINK=$(echo $SINK | awk '{ print $1 }')
# Get AUX input
AUX=$(runuser -l pi -c "pactl list short sources | grep 'alsa_input.usb'")
AUX=$(echo $AUX | awk '{ print $1 }')
# Get DAB input
DAB=$(runuser -l pi -c "pactl list short sources | grep 'alsa_input.platform-soc'")
DAB=$(echo $DAB | awk '{ print $1 }')

# Set backlight pin to PWM
gpio -g mode 12 pwm
# Enable pullup of Ignition pin
gpio -g mode 13 up

# OBD connection for Steering Wheel and other keys
sudo /usr/bin/python3 /boot/OAP-Config/OBD/obd-keys.py &

# Bootup the DAB radio (and output to I2S)
sudo /opt/OAP/radio_cli -b D -o 1
# Redirect DAB audio to output
runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=$SINK"

# Some variables
AUX_STATE=0
MODULE_ID=0

# Main loop for: (checking inputs, )
while true; do
    # Shutdown trigger
    IGNITION_GPIO=`gpio -g read 13`
    if [ $IGNITION_GPIO -ne 0 ] ; then
        if [ ! -f /tmp/android_device ] && [ ! -f /tmp/btdevice ]; then # this needs to be implemented, see issue #14
            sudo shutdown -h now
        fi
    fi
    # AUX redirect trigger
    AUX_GPIO=`gpio -g read 22`
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
