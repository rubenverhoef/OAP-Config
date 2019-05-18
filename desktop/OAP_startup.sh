#!/bin/bash

RUNNING=$(ps aux | grep "/usr/local/bin/autoapp" | grep --invert-match "grep")

if [ -z "$RUNNING" ]; then
    /usr/local/bin/openauto
else
    xdotool key F12
fi

exit 0
