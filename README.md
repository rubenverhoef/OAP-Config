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

`git clone https://github.com/rubenverhoef/OAP-Config.git /home/pi/OAP-Config --recurse-submodules`

### To update:
```
cd /home/pi/OAP-Config && git reset --hard origin/master
cd /home/pi/OAP-Config && git pull origin master
```
