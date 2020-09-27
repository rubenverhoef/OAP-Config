#!/bin/bash

BLUETOOTH_DIR=/var/lib/bluetooth

OBD_MAC=$(cat /home/pi/.openauto/config/openauto_system.ini | grep "ObdAdapterRfCommAddress" | cut -d "=" -f 2)

for (( ; ; ))
do
    sleep 10

    # Connect Phone:
    PHONE_CONNECTED=$(hcitool con | grep --invert "$OBD_MAC" | grep -o -E 'handle [1-9]+')
    
    if [ -z "$PHONE_CONNECTED" ]; then # when we are not connected to a device
        for CONTROLLER_DIR in ${BLUETOOTH_DIR}/*; do
            if [ ! -z "$PHONE_CONNECTED" ]; then # when we are connected to a device
                break
            fi
            
            CONTROLLER_MAC=$(basename ${CONTROLLER_DIR})
            if [ -d "${CONTROLLER_DIR}" ] && [[ $CONTROLLER_MAC =~ ^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$ ]] ; then
                for DEVICE_DIR in ${CONTROLLER_DIR}/*; do
                    DEVICE_MAC=$(basename ${DEVICE_DIR})
                    if [ -d "${DEVICE_DIR}" ] && [[ $DEVICE_MAC =~ ^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$ ]] ; then
                        if grep "Trusted=true" ${DEVICE_DIR}/info > /dev/null ; then
                            if [ $DEVICE_MAC != "$OBD_MAC" ] ; then
                                echo "Connecting to phone:" ${DEVICE_MAC}
                                echo -e "select ${CONTROLLER_MAC}\nconnect ${DEVICE_MAC}\nquit" | bluetoothctl > /dev/null 2>&1
                                sleep 10
                                PHONE_CONNECTED=$(hcitool con | grep --invert "$OBD_MAC" | grep -o -E 'handle [1-9]+')

                                if [ ! -z "$PHONE_CONNECTED" ]; then # when we are connected to a device
                                    echo "Connected to phone:" ${DEVICE_MAC}
                                    break
                                else
                                    echo "Couldn't connect to phone:" ${DEVICE_MAC}
                                fi
                            fi
                        fi
                    fi
                done
            fi
        done
    fi
    
    # Connect OBD:
    OBD_CONNECTED=$(hcitool con | grep "$OBD_MAC" | grep -o -E 'handle [1-9]+')

    if [ -z "$OBD_CONNECTED" ]; then # when we are not connected to a device
        for CONTROLLER_DIR in ${BLUETOOTH_DIR}/*; do
            if [ ! -z "$OBD_CONNECTED" ]; then # when we are connected to a device
                break
            fi
            
            CONTROLLER_MAC=$(basename ${CONTROLLER_DIR})
            if [ -d "${CONTROLLER_DIR}" ] && [[ $CONTROLLER_MAC =~ ^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$ ]] ; then
                for DEVICE_DIR in ${CONTROLLER_DIR}/*; do
                    DEVICE_MAC=$(basename ${DEVICE_DIR})
                    if [ -d "${DEVICE_DIR}" ] && [[ $DEVICE_MAC =~ ^([0-9A-F]{2}[:]){5}([0-9A-F]{2})$ ]] ; then
                        if grep "Trusted=true" ${DEVICE_DIR}/info > /dev/null ; then
                            if [ $DEVICE_MAC == "$OBD_MAC" ] ; then
                                echo "Connecting to OBD:" ${OBD_MAC}
                                echo -e "select ${CONTROLLER_MAC}\nconnect ${OBD_MAC}\nquit" | bluetoothctl > /dev/null 2>&1
                                sleep 10
                                OBD_CONNECTED=$(hcitool con | grep "$OBD_MAC" | grep -o -E 'handle [1-9]+')

                                if [ ! -z "$OBD_CONNECTED" ]; then # when we are connected to a device
                                    echo "Connected to OBD:" ${OBD_MAC}
                                    break
                                else
                                    echo "Couldn't connect to OBD:" ${OBD_MAC}
                                fi
                            fi
                        fi
                    fi
                done
            fi
        done
    fi

    if [ ! -z "$PHONE_CONNECTED" ]; then
        echo "Phone is connected!"
    fi
    if [ ! -z "$OBD_CONNECTED" ]; then
        echo "OBD is connected!"
    fi
done

exit 1
