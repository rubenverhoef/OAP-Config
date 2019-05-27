#!/bin/bash

# Feed the dog
sudo touch /dev/watchdog

# Get audio output
SINK=$(runuser -l pi -c "pactl list short sources | grep 'alsa_output.usb-Burr-Brown' | grep --invert-match 'echo'")
SINK=$(echo $SINK | awk '{ print $1 }')
# Get AUX input
AUX=$(runuser -l pi -c "pactl list short sources | grep 'alsa_input.usb-Burr-Brown'")
AUX=$(echo $AUX | awk '{ print $1 }')
# Get DAB input
DAB=$(runuser -l pi -c "pactl list short sources | grep 'alsa_input.platform-soc'")
DAB=$(echo $DAB | awk '{ print $1 }')

# Check all audio variables
if [ -z "$SINK" ] || [ -z "$AUX" ] || [ -z "$DAB" ]; then
    if [ ! -f "/home/pi/audio_error.sh" ]; then
        echo "SINK="$SINK >> /home/pi/audio_error.sh
        echo "AUX="$AUX >> /home/pi/audio_error.sh
        echo "DAB="$DAB >> /home/pi/audio_error.sh  
        sudo reboot
        exit 0
    else
        echo "SINK="$SINK >> /home/pi/fatal_audio_error.sh
        echo "AUX="$AUX >> /home/pi/fatal_audio_error.sh
        echo "DAB="$DAB >> /home/pi/fatal_audio_error.sh  
    fi
else
    rm -f /home/pi/audio_error.sh
fi

# Set backlight pin to PWM
gpio -g mode 12 pwm
# Enable pullup of Ignition pin
gpio -g mode 13 up

# Bootup the DAB radio (and output to I2S)
sudo killall radio_cli
sudo /opt/OAP/radio_cli -b D -o 1

# Create virtual sink named Faded for all music audio (DAB, AUX, AA_MUSIC)
if [ -z "$(runuser -l pi -c "pactl list sinks short" | grep "Faded")" ]; then
    echo "Creating Faded sink"
    runuser -l pi -c "pactl load-module module-null-sink sink_name=Faded sink_properties=device.description='Faded_Sink'"
fi
# Create virtual sink named Voice for all AA voices
if [ -z "$(runuser -l pi -c "pactl list sinks short" | grep "Voice")" ]; then
    echo "Creating Voice sink"
    runuser -l pi -c "pactl load-module module-null-sink sink_name=Voice sink_properties=device.description='Voice_Sink'"
fi
# Make Voice default (so we can change the volume from OAP)
runuser -l pi -c "pacmd set-default-sink Voice"
# Redirect Faded to audio output sink
if [ -z "$(runuser -l pi -c "pacmd list-sink-inputs" | grep "Faded")" ]; then
    echo "Redirecting Faded to Sink"
    runuser -l pi -c "pactl load-module module-loopback source=Faded.monitor sink=$SINK"
fi
# Redirect Voice to audio output sink
if [ -z "$(runuser -l pi -c "pacmd list-sink-inputs" | grep "Voice")" ]; then
    echo "Redirecting Voice to Sink"
    runuser -l pi -c "pactl load-module module-loopback source=Voice.monitor sink=$SINK"
fi
# Redirect DAB audio to faded output
DAB_MOD=$(runuser -l pi -c "pacmd list-sink-inputs" | grep "alsa_input.platform-soc")
if [ -z "$DAB_MOD" ]; then
    echo "Redirecting DAB to Sink"
    DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")
fi

# Some variables
TIME_SET_TRY=0
IGNITION_CNT=0
TIME_SET=0
AUX_STATE=0
FADE_STATE=0
SET_SINK=0
AUX_MOD=0
OLD_VOLUME=100%

# Main loop for: (checking inputs, )
for (( ; ; ))
do
    # Feed the dog
    sudo touch /dev/watchdog
    
    # Shutdown trigger
    AA_RUNNING=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | awk '{ print $1 }')
    AA_ASSISTANT=$(runuser -l pi -c "pacmd list-source-outputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "/r/n%s ", $2;} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "mono" | grep "autoapp" | awk '{ print $1 }')
    AA_VOICE=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "RUNNING" | grep "mono"  | awk '{ print $1 }')

    if [ -z "$AA_RUNNING" ]; then
        SET_SINK=0
        IGNITION_GPIO=`gpio -g read 13`
        if [ $IGNITION_GPIO -ne 0 ]; then
            let "IGNITION_CNT++"
            if [ $IGNITION_CNT -gt 10 ]; then
                sudo shutdown -h now
                exit 0
            fi
        else
            IGNITION_CNT=0
        fi
    elif [ $SET_SINK -ne 1 ]; then
        SET_SINK=1
        FIRST_INPUT=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono"  | awk '{ print $1 }' | sed -n '1p')
        SECOND_INPUT=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono"  | awk '{ print $1 }' | sed -n '2p')
        AA_MUSIC=$(runuser -l pi -c "pacmd list-sink-inputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "front"  | awk '{ print $1 }')
        runuser -l pi -c "pacmd move-sink-input $FIRST_INPUT Voice"
        runuser -l pi -c "pacmd move-sink-input $SECOND_INPUT Voice"
        runuser -l pi -c "pacmd move-sink-input $AA_MUSIC Faded"
    fi
    # AUX redirect trigger
    AUX_GPIO=`gpio -g read 22`
    if [ $AUX_GPIO -ne 1 ] && [ $AUX_STATE -ne 1 ]; then
        # Redirect AUX audio to faded output
        AUX_STATE=1
        runuser -l pi -c "pactl unload-module $DAB_MOD"
        AUX_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$AUX sink=Faded")
    elif [ $AUX_GPIO -ne 0 ] && [ $AUX_STATE -ne 0 ]; then
        # Disable AUX redirect
        AUX_STATE=0
        runuser -l pi -c "pactl unload-module $AUX_MOD"
        DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")
    fi
    # Mute faded group when AA is talking, playing music or listening
    if [ -z "$AA_ASSISTANT" ] && [ -z "$AA_VOICE" ] ; then
        if [ $FADE_STATE -ne 0 ]; then
            runuser -l pi -c "pactl set-sink-volume Faded $OLD_VOLUME"
            FADE_STATE=0
        fi
    elif [ $FADE_STATE -ne 1 ]; then
        OLD_VOLUME=$(runuser -l pi -c "pactl list sinks" | awk 'BEGIN { ORS=" " } /Name:/ {printf "\r\n%s ", $2;} /Volume:/ {print $5};' | grep "Faded" | awk '{ print $2 }')
        runuser -l pi -c "pactl set-sink-volume Faded 0%"
        FADE_STATE=1
    fi

    # Set time from DAB radio
    if [ $TIME_SET -ne 1 ]; then
        if [ $TIME_SET_TRY -lt 100 ]; then
            let "TIME_SET_TRY++"
            TIME=$(sudo /opt/OAP/radio_cli -t | grep T.*Z | sed 's/T/ /; s/Z/ /')
            YEAR=$(echo $TIME | awk '{ print $1 }' | sed 's/-.*//')

            if [ -n "$TIME" ] && [ "$YEAR" -gt "0" ]; then
                TIME_SET=1
                sudo date -s "$TIME" --utc
            fi
        fi
    fi
done

exit 1
