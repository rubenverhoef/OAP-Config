#!/bin/bash

# Wait for pulseaudio
PULSEAUDIO=$(runuser -l pi -c "pulseaudio --check")
while [ ! -z "$PULSEAUDIO" ]
do
    # Feed the dog
    sudo touch /dev/watchdog
    echo "Sleep"
    sleep 5
    PULSEAUDIO=$(runuser -l pi -c "pulseaudio --check")
done
sleep 5

# Get audio output
PACTL_SOURCES=$(runuser -l pi -c "pactl list short sources")
PACTL_SINKS=$(runuser -l pi -c "pactl list sinks short")
PACMD_INPUTS=$(runuser -l pi -c "pacmd list-sink-inputs")

SINK=$(echo "$PACTL_SOURCES" | grep 'alsa_output.usb-Burr-Brown' | grep --invert-match 'echo' | awk '{ print $1 }')
# Get AUX input
AUX=$(echo "$PACTL_SOURCES" | grep 'alsa_input.usb-Burr-Brown' | awk '{ print $1 }')
# Get DAB input
DAB=$(echo "$PACTL_SOURCES" | grep 'alsa_input.platform-soc_sound' | awk '{ print $1 }')
# Get Mic input
MIC=$(echo "$PACTL_SOURCES" | grep 'alsa_input.usb-045e_USB_camera-01' | awk '{ print $1 }')

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

# Create virtual sink named Faded for all music audio (DAB, AUX, AA_MUSIC, A2DP)
if [ -z "$(echo "$PACTL_SINKS" | grep "Faded")" ]; then
    echo "Creating Faded sink"
    runuser -l pi -c "pactl load-module module-null-sink sink_name=Faded sink_properties=device.description='Faded_Sink'"
fi
# Create virtual sink named Voice for all AA voices
if [ -z "$(echo "$PACTL_SINKS" | grep "Voice")" ]; then
    echo "Creating Voice sink"
    runuser -l pi -c "pactl load-module module-null-sink sink_name=Voice sink_properties=device.description='Voice_Sink'"
fi
# Make Voice default (so we can change the volume from OAP)
runuser -l pi -c "pacmd set-default-sink Voice"
# Make MIC input default
runuser -l pi -c "pacmd set-default-source $MIC"
# Redirect Faded to audio output sink
if [ -z "$(echo "$PACMD_INPUTS" | grep "Faded")" ]; then
    echo "Redirecting Faded to Sink"
    runuser -l pi -c "pactl load-module module-loopback source=Faded.monitor sink=$SINK"
fi
# Redirect Voice to audio output sink
if [ -z "$(echo "$PACMD_INPUTS" | grep "Voice")" ]; then
    echo "Redirecting Voice to Sink"
    runuser -l pi -c "pactl load-module module-loopback source=Voice.monitor sink=$SINK"
fi
# Redirect DAB audio to faded output
DAB_MOD=$(echo "$PACMD_INPUTS" | grep "alsa_input.platform-soc")
if [ -z "$DAB_MOD" ]; then
    echo "Redirecting DAB to Sink"
    DAB_MOD=$(runuser -l pi -c "pactl load-module module-loopback source=$DAB sink=Faded")
fi

# Set faded and output to 100% volume
runuser -l pi -c "pactl set-sink-volume Faded 100%"
runuser -l pi -c "pactl set-sink-volume Voice 100%"
runuser -l pi -c "pactl set-sink-volume $SINK 100%"

# Some variables
IGNITION_CNT=0
AUX_STATE=0
MUTE_STATE=0
FADE_STATE=0
SET_SINK_AA=0
SET_SINK_A2DP=0
AUX_MOD=0
LOWER_VOLUME="30%"
OLD_VOLUME="100%"

# Main loop for: (checking inputs, )
for (( ; ; ))
do
    # Feed the dog
    sudo touch /dev/watchdog
    
    # Audio sources
    PACMD_INPUTS=$(runuser -l pi -c "pacmd list-sink-inputs")
    AA_RUNNING=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono" | awk '{ print $1 }')
    AA_ASSISTANT=$(runuser -l pi -c "pacmd list-source-outputs" | awk 'BEGIN { ORS=" " } /index:/ {printf "/r/n%s ", $2;} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "mono" | grep "autoapp" | awk '{ print $1 }')
    AA_VOICE=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "RUNNING" | grep "mono"  | awk '{ print $1 }')
    A2DP=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /channel map:/ {print $3} /media.icon_name =/ {print $3} /media.role =/ {print $3};' | grep "audio-card-bluetooth" | grep "front" | awk '{ print $1 }')
    CALL=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /sink:/ {print $3};' | grep "headset_audio_gateway" | grep "RUNNING" | awk '{ print $1 }')

    IGNITION_GPIO=`gpio -g read 13`
    if [ $IGNITION_GPIO -ne 1 ]; then
        let "IGNITION_CNT++"
        if [ $IGNITION_CNT -gt 10 ]; then
            sudo shutdown -h now
            exit 0
        fi
    else
        IGNITION_CNT=0
    fi

    if [ -z "$AA_RUNNING" ]; then
        SET_SINK_AA=0
    elif [ $SET_SINK_AA -ne 1 ]; then
        SET_SINK_AA=1
        PACMD_INPUTS=$(runuser -l pi -c "pacmd list-sink-inputs")
        FIRST_INPUT=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono"  | awk '{ print $1 }' | sed -n '1p')
        SECOND_INPUT=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "mono"  | awk '{ print $1 }' | sed -n '2p')
        AA_MUSIC=$(echo "$PACMD_INPUTS" | awk 'BEGIN { ORS=" " } /index:/ {printf "\r\n%s ", $2;} /state:/ {print $2} /channel map:/ {print $3} /application.process.binary =/ {print $3};' | grep "autoapp" | grep "front"  | awk '{ print $1 }')
        runuser -l pi -c "pacmd move-sink-input $FIRST_INPUT Voice"
        runuser -l pi -c "pacmd move-sink-input $SECOND_INPUT Voice"
        runuser -l pi -c "pacmd move-sink-input $AA_MUSIC Faded"
    fi

    if [ -z "$A2DP" ]; then
        SET_SINK_A2DP=0
    elif [ $SET_SINK_A2DP -ne 1 ]; then
        SET_SINK_A2DP=1
        runuser -l pi -c "pacmd move-sink-input $A2DP Faded"
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
    # Lower volume faded group when AA is talking or in reverse gear
    REVERSE_GEAR=`gpio -g read 17`
    if [ -z "$AA_VOICE" ] && [ $REVERSE_GEAR -ne 1 ]; then
        if [ $FADE_STATE -ne 0 ]; then
            runuser -l pi -c "pactl set-sink-volume Faded 100%"
            FADE_STATE=0
        fi
    elif [ $FADE_STATE -ne 1 ]; then
        runuser -l pi -c "pactl set-sink-volume Faded $LOWER_VOLUME"
        FADE_STATE=1
    fi
    # Mute faded when calling, or AA is listening
    if [ -z "$CALL" ] && [ -z "$AA_ASSISTANT" ]; then
        if [ $MUTE_STATE -ne 0 ]; then
            runuser -l pi -c "pactl set-sink-volume Faded 100%"
            runuser -l pi -c "pactl set-sink-volume Voice $OLD_VOLUME"
            MUTE_STATE=0
        fi
    elif [ $MUTE_STATE -ne 1 ]; then
        OLD_VOLUME=$(runuser -l pi -c "pactl list sinks" | awk 'BEGIN { ORS=" " } /Name:/ {printf "\r\n%s ", $2;} /Volume:/ {print $5};' | grep "Voice" | awk '{ print $2 }')
        runuser -l pi -c "pactl set-sink-volume Faded 0%"
        runuser -l pi -c "pactl set-sink-volume Voice 0%"
        MUTE_STATE=1
    fi
done

exit 1
