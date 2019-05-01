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
# Make Faded default
runuser -l pi -c "pacmd set-default-sink Faded"
# Redirect DAB audio to faded output
DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")

# Some variables
AUX_STATE=0
FADE_STATE=0
SET_SINK=0
AUX_MOD=0

# Main loop for: (checking inputs, )
for (( ; ; ))
do
    # Shutdown trigger
    AA_RUNNING=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | awk '{ print $1 }')
    AA_ASSISTANT=$(runuser -l pi -c "pacmd list-source-outputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "/r/n%s ", $2;} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "mono" | grep "autoapp" | awk '{ print $1 }')
    AA_VOICE=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "RUNNING" | grep "mono"  | awk '{ print $1 }')

    if [ -z "$AA_RUNNING" ]; then
        SET_SINK=0
        IGNITION_GPIO=`gpio -g read 13`
        if [ $IGNITION_GPIO -ne 0 ]; then
            sudo shutdown -h now
        fi
    elif [ $SET_SINK -ne 1 ]; then
        SET_SINK=1
        FIRST_INPUT=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono"  | awk '{ print $1 }' | sed -n '1p')
        SECOND_INPUT=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono"  | awk '{ print $1 }' | sed -n '2p')
        AA_MUSIC=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "front"  | awk '{ print $1 }')
        runuser -l pi -c "pacmd move-sink-input $FIRST_INPUT $SINK"
        runuser -l pi -c "pacmd move-sink-input $SECOND_INPUT $SINK"
        runuser -l pi -c "pacmd move-sink-input $AA_MUSIC Faded"
    fi
    # AUX redirect trigger
    AUX_GPIO=`gpio -g read 22`
    if [ $AUX_GPIO -ne 0 ] && [ $AUX_STATE -ne 1 ]; then
        # Redirect AUX audio to faded output
        AUX_STATE=1
        runuser -l pi -c "pactl unload-module $DAB_MOD"
        AUX_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$AUX sink=Faded")
    elif [ $AUX_GPIO -ne 1 ] && [ $AUX_STATE -ne 0 ]; then
        # Disable AUX redirect
        AUX_STATE=0
        runuser -l pi -c "pactl unload-module $AUX_MOD"
        DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")
    fi
    # Mute faded group when AA is talking, playing music or listening
    if [ -z "$AA_ASSISTANT" ] && [ -z "$AA_VOICE" ] ; then
        if [ $FADE_STATE -ne 0 ]; then
            FADE_STATE=0
            runuser -l pi -c "pactl set-sink-volume Faded 100%"
        fi
    elif [ $FADE_STATE -ne 1 ]; then
        FADE_STATE=1
        runuser -l pi -c "pactl set-sink-volume Faded 0%"
    fi
done

exit 0
