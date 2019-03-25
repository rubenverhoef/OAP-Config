#!/bin/bash

# do whatever you need to do here
# by default this does nothing

# PWM backlight init
gpio -g mode 12 pwm

# OBD connection for Steering Wheel and other keys
# sudo /usr/bin/python3 /boot/OAP-Config/OBD/obd-keys.py &
