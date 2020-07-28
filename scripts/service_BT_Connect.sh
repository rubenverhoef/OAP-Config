#!/bin/bash

BLUETOOTH_DIR=/var/lib/bluetooth

for (( ; ; ))
do
    sleep 10
    CONNECTED=$(hcitool con | grep -o -E 'handle [1-9]+')
    
    if [ -z "$CONNECTED" ]; then # when we are not connected to a device
        for CONTROLLER_DIR in ${BLUETOOTH_DIR}/*; do
            if [ ! -z "$CONNECTED" ]; then # when we are connected to a device
                break
            fi
            
            CONTROLLER_MAC=$(basename ${CONTROLLER_DIR})
            if [ -d "${CONTROLLER_DIR}" ] && [[ $CONTROLLER_MAC =~ ^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$ ]] ; then
                for DEVICE_DIR in ${CONTROLLER_DIR}/*; do
                    DEVICE_MAC=$(basename ${DEVICE_DIR})
                    if [ -d "${DEVICE_DIR}" ] && [[ $DEVICE_MAC =~ ^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$ ]] ; then
                        if grep "Trusted=true" ${DEVICE_DIR}/info > /dev/null ; then
                            echo "Connecting to:" ${DEVICE_MAC}
                            echo -e "select ${CONTROLLER_MAC}\nconnect ${DEVICE_MAC}\nquit" | bluetoothctl > /dev/null 2>&1
                            sleep 10
                            CONNECTED=$(hcitool con | grep -o -E 'handle [1-9]+')

                            if [ ! -z "$CONNECTED" ]; then # when we are connected to a device
                                echo "Connected to:" ${DEVICE_MAC}
                                break
                            else
                                echo "Couldn't connect to:" ${DEVICE_MAC}
                            fi
                        fi
                    fi
                done
            fi
        done
    fi
done

exit 1
