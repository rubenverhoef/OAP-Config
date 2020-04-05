# OAP-Config
OpenAuto Pro Custom scripts and config

## Features:
- DAB Radio using the [uGreen DABBoard](https://ugreen.eu/product/ugreen-dab-board/)
- ...

## Getting started:
Flash latest OAP to the SD card.  
Now edit config.txt to your display settings.  
Create a file `openauto_license.dat` containing your OAP license key at `/boot/` partition root.  
Create a file `wpa_supplicant.conf` with your wifi settings to connect to internet (for instance a phone hotspot) at `/boot/` partition root.  
The `wpa_supplicant.conf` file must contain:
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=NL

network={
    ssid="Phone Hotspot SSID"
    psk="Phone Hotspot password"
    key_mgmt=WPA-PSK
}

```

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
