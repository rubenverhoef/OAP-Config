#!/bin/bash

# Some variables
TIME_SET_TRY=0
TIME_SET=0
trycnt=10
bootup=0
err=0
Argument=""

if [ ! -f "/home/pi/TuneStation" ]; then
    touch /home/pi/TuneStation
fi

if [ -z "$1" ]; then
    for (( ; ; ))
    do
        if [ "$bootup" -eq 0 ] || [ $err -ge $trycnt ]; then
            bootup=1
            err=0
            while read line; do
                Argument="$line"
            done </home/pi/TuneStation
        else
            while read j
            do
                while read line; do
                    Argument="$line"
                done </home/pi/TuneStation
            done <  <(inotifywait -q -e modify /home/pi/TuneStation)
        fi

        if [[ "$Argument" == *"-k"* ]]; then
            DAB_State=$(/opt/OAP/radio_cli -i | grep "not booted up, no firmware loaded")
            while [ -z "$DAB_State" ] && [ $err -lt $trycnt ]; do
                echo "Powering down DABBoard"
                DAB_State=$(/opt/OAP/radio_cli -k | grep "Si468x shut down")
                err=$((err+1))
            done
            if [ $err -lt $trycnt ]; then
                err=0
                echo "DABBoard Shut down"
            else
                echo "could not Shut down"
            fi 
        elif [[ "$Argument" == *"-c"* ]] && [[ "$Argument" == *"-e"* ]] && [[ "$Argument" == *"-f"* ]]; then
            # Check if DABBoard is booted otherwise boot it up
            DAB_State=$(/opt/OAP/radio_cli -i | grep "Chip info")
            while [ -z "$DAB_State" ] && [ $err -lt $trycnt ]; do
                echo "Booting up DABBoard..."
                DAB_State=$(/opt/OAP/radio_cli -b D -o 1 | grep "Boot up successful")
                err=$((err+1))
            done
            if [ $err -lt $trycnt ]; then
                err=0
                echo "DABBoard booted up"
            else
                echo "could not boot"
            fi 

            # Tune to specific radio channel
            Tune_State=""
            while [ -z "$Tune_State" ] && [ $err -lt $trycnt ]; do
                echo "Tuning to $Argument ..."
                Tune_State=$(/opt/OAP/radio_cli $Argument -p | grep "Tuned.")
                err=$((err+1))
            done
            if [ $err -lt $trycnt ]; then
                err=0
                echo "Tuned!"
            else
                echo "could not tune"
            fi 
            
            # Set time from DAB radio
            if [ $TIME_SET -ne 1 ]; then
                if [ $TIME_SET_TRY -lt 100 ]; then
                    let "TIME_SET_TRY++"
                    TIME=$(/opt/OAP/radio_cli -t | grep T.*Z | sed 's/T/ /; s/Z/ /')
                    YEAR=$(echo $TIME | awk '{ print $1 }' | sed 's/-.*//')
                    if [ -n "$TIME" ] && [ "$YEAR" -gt "0" ]; then
                        TIME_SET=1
                        sudo date -s "$TIME" --utc
                        echo "Time set to: $TIME"
                    fi
                fi
            fi
        else
            /opt/OAP/radio_cli $Argument
        fi
    done
else
    echo "$@" > /home/pi/TuneStation
fi
exit 1
