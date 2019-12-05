#!/bin/bash

sudo killall radio_cli
sudo /opt/OAP/radio_cli -c $1 -e $2 -f $3 -p

exit 0
