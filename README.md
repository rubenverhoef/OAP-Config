# OAP-Config
OpenAuto Pro Custom scripts and config

## Features:
- DAB Radio using the [uGreen DABBoard](https://ugreen.eu/product/ugreen-dab-board/)
- ...

## Getting it:
For cloning use:

`sudo git clone https://github.com/rubenverhoef/OAP-Config.git /boot/OAP-Config --recurse-submodules`

### To update:
```
cd /boot/OAP-Config && sudo git reset --hard origin/master
cd /boot/OAP-Config && sudo git pull origin master
```

# display config.txt:
````
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1024 600 60 6 0 0 0
hdmi_drive=1
````
