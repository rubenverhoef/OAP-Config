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

# Create virtual sink named Faded
runuser -l pi -c "pactl load-module module-null-sink sink_name=Faded sink_properties=device.description='Faded_Sink'"
# Redirect Virtual sink to audio output sink
runuser -l pi -c "pactl load-module module-loopback source=Faded.monitor sink=$SINK"
# Redirect DAB audio to faded output
DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")

# Some variables
AUX_STATE=0
AUX_MOD=0

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
        # Redirect AUX audio to faded output
        AUX_STATE=1
        runuser -l pi -c "pactl unload-module $DAB_MOD"
        AUX_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$AUX sink=Faded")
    elif [ $AUX_GPIO -ne 1 ] && [$AUX_STATE -ne 0]; then
        # Disable AUX redirect
        AUX_STATE=0
        runuser -l pi -c "pactl unload-module $AUX_MOD"
        DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")
    fi
    AA_VOICE=$(pacmd list-sink-inputs | awk 'BEGIN { ORS=" " } /index:/ {print $2} /state:/ {print $2} /application.process.binary =/ {print $3} /channel map:/ {printf "%s\n\r", $3;};' | grep "RUNNING" | grep "mono" | grep "autoapp" | awk '{ print $2 }')
    AA_ASSISTANT=$(pacmd list-source-outputs | awk 'BEGIN { ORS=" " } /index:/ {print $2} /application.process.binary =/ {print $3} /channel map:/ {printf "%s\n\r", $3;};' | grep "mono" | grep "autoapp" | awk '{ print $2 }')
    AA_MUSIC=$(pacmd list-sink-inputs | awk 'BEGIN { ORS=" " } /index:/ {print $2} /state:/ {print $2} /application.process.binary =/ {print $3} /channel map:/ {printf "%s\n\r", $3;};' | grep "RUNNING" | grep "front" | grep "autoapp" | awk '{ print $2 }')
    if [ $AA_VOICE ] || [ $AA_ASSISTANT ] || [ $AA_MUSIC ]; then
        runuser -l pi -c "pactl set-sink-volume Faded 0%"
    else
        runuser -l pi -c "pactl set-sink-volume Faded 100%"
    fi
    sleep 0.1
done

exit 0
