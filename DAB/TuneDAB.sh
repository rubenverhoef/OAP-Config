#!/bin/bash

sudo killall radio_cli
sudo /opt/OAP/radio_cli -b D -o 1 -c $1 -e $2 -f $3 -p

exit 0
