#!/bin/bash

# Activate SSH root
function remove_ssh_message() {
    sudo rm -f /etc/profile.d/sshpwd.sh
    sudo rm -f /etc/xdg/lxsession/LXDE-pi/sshpwd.sh
}

# Set Wallpaper
function set_wallpaper() {
    install -m 644 /boot/OAP-Config/wallpaper.png                      "/home/pi"
    sudo sed -i "s/wallpaper=.*/wallpaper=\/home\/pi\/wallpaper.png/g" /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
}

# Install services
function install_services() {
    install -m 644 /boot/OAP-Config/services/user_startup.service                "/etc/systemd/system/"
    install -m 644 /boot/OAP-Config/services/gpio_shutdown.service               "/etc/systemd/system/"
    # install -m 644 /boot/OAP-Config/services/hwclock-load.service                "/etc/systemd/system/"
    # install -m 644 /boot/OAP-Config/services/custombrightness.service            "/etc/systemd/system/"
    # install -m 644 /boot/OAP-Config/services/alsastaterestore.service            "/etc/systemd/system/"

    install -d "/opt/OAP"
    install -m 755 /boot/OAP-Config/scripts/service_user_startup.sh             "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/service_gpio_shutdown.sh            "/opt/OAP/"
    # install -m 755 /boot/OAP-Config/scripts/service_hwclock.sh                  "/opt/OAP/"
    # install -m 755 /boot/OAP-Config/scripts/service_custombrightness.sh         "/opt/OAP/"
    # install -m 755 /boot/OAP-Config/scripts/service_alsastaterestore.sh         "/opt/OAP/"
}

# Activate services
function activate_services() {
    systemctl enable user_startup.service
    systemctl enable gpio_shutdown.service
    #systemctl enable hwclock-load.service
    #systemctl enable custombrightness.service
    # systemctl enable alsastaterestore.service
}

# Shutdown functions
function relay_config() {
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i 's/^dtoverlay=gpio-poweroff.*//' /boot/config.txt
    sudo sed -i 's/^# GPIO triggerd poweroff.*//' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# GPIO triggerd poweroff' >> /boot/config.txt"
    sudo sh -c "echo 'dtoverlay=gpio-poweroff,gpiopin=5,active_low="y"' >> /boot/config.txt"
}

# Power settings
function power_config() {
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i 's/^max_usb_current.*//' /boot/config.txt
    sudo sed -i 's/^# Custom power settings.*//' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# Custom power settings' >> /boot/config.txt"
    sudo sh -c "echo 'max_usb_current=1' >> /boot/config.txt"
}

# RTC functions
function rtc() {
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i 's/^# RTC Setup.*//' /boot/config.txt
    sudo sed -i '/dtoverlay=i2c-rtc/d' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /etc/modules
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# RTC Setup' >> /boot/config.txt"
    sudo sh -c "echo 'dtoverlay=i2c-rtc,'$1 >> /boot/config.txt"
    sudo systemctl enable hwclock-load.service >/dev/null 2>&1
    sudo systemctl daemon-reload
	sudo timedatectl set-timezone "$(cat /etc/timezone)"
    check_i2c
}

# Audio functions
function audio_audioinjector() {
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i 's/^dtparam=audio=.*//' /boot/config.txt
    sudo sed -i 's/^dtoverlay=audioinjector.*//' /boot/config.txt
    sudo sed -i 's/^dtparam=i2s=on.*//' /boot/config.txt
    sudo sed -i 's/^# Audio Setup.*//' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# Audio Setup' >> /boot/config.txt"
    sudo sh -c "echo 'dtoverlay=audioinjector-'$1 >> /boot/config.txt"
    sudo sh -c "echo 'dtparam=i2s=on' >> /boot/config.txt"
    check_i2c
}

function check_i2c() {
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i '/dtoverlay=i2c_arm=/d' /boot/config.txt
    sudo sed -i 's/^# I2C Bus.*//' /boot/config.txt
    sudo sed -i '/i2c*/d' /etc/modules
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /etc/modules
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# I2C Bus' >> /boot/config.txt"
    sudo sh -c "echo 'dtoverlay=i2c_arm=on' >> /boot/config.txt"
    sudo sh -c "echo 'i2c-dev' >> /etc/modules"
}

function audio_audioinjector_controls() {
    TEMPSTATE="/tmp/alsa.dummy"
    echo "state.audioinjectorpi {" > $TEMPSTATE
    echo "	control.1 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Master Playback Volume'" >> $TEMPSTATE
    echo "		value.0 121" >> $TEMPSTATE
    echo "		value.1 121" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type INTEGER" >> $TEMPSTATE
    echo "			count 2" >> $TEMPSTATE
    echo "			range '0 - 127'" >> $TEMPSTATE
    echo "			dbmin -9999999" >> $TEMPSTATE
    echo "			dbmax 600" >> $TEMPSTATE
    echo "			dbvalue.0 0" >> $TEMPSTATE
    echo "			dbvalue.1 0" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.2 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Master Playback ZC Switch'" >> $TEMPSTATE
    echo "		value.0 false" >> $TEMPSTATE
    echo "		value.1 false" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 2" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.3 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Capture Volume'" >> $TEMPSTATE
    echo "		value.0 31" >> $TEMPSTATE
    echo "		value.1 31" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type INTEGER" >> $TEMPSTATE
    echo "			count 2" >> $TEMPSTATE
    echo "			range '0 - 31'" >> $TEMPSTATE
    echo "			dbmin -3450" >> $TEMPSTATE
    echo "			dbmax 1200" >> $TEMPSTATE
    echo "			dbvalue.0 1200" >> $TEMPSTATE
    echo "			dbvalue.1 1200" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.4 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Line Capture Switch'" >> $TEMPSTATE
    echo "		value.0 false" >> $TEMPSTATE
    echo "		value.1 false" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 2" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.5 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Mic Boost Volume'" >> $TEMPSTATE
    echo "		value 1" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type INTEGER" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "			range '0 - 1'" >> $TEMPSTATE
    echo "			dbmin 0" >> $TEMPSTATE
    echo "			dbmax 2000" >> $TEMPSTATE
    echo "			dbvalue.0 2000" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.6 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Mic Capture Switch'" >> $TEMPSTATE
    echo "		value true" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.7 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Sidetone Playback Volume'" >> $TEMPSTATE
    echo "		value 0" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type INTEGER" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "			range '0 - 3'" >> $TEMPSTATE
    echo "			dbmin -1500" >> $TEMPSTATE
    echo "			dbmax -600" >> $TEMPSTATE
    echo "			dbvalue.0 -1500" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.8 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'ADC High Pass Filter Switch'" >> $TEMPSTATE
    echo "		value true" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.9 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Store DC Offset Switch'" >> $TEMPSTATE
    echo "		value false" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.10 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Playback Deemphasis Switch'" >> $TEMPSTATE
    echo "		value false" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.11 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Output Mixer Line Bypass Switch'" >> $TEMPSTATE
    echo "		value false" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.12 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Output Mixer Mic Sidetone Switch'" >> $TEMPSTATE
    echo "		value false" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.13 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Output Mixer HiFi Playback Switch'" >> $TEMPSTATE
    echo "		value true" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type BOOLEAN" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "	control.14 {" >> $TEMPSTATE
    echo "		iface MIXER" >> $TEMPSTATE
    echo "		name 'Input Mux'" >> $TEMPSTATE
    echo "		value Mic" >> $TEMPSTATE
    echo "		comment {" >> $TEMPSTATE
    echo "			access 'read write'" >> $TEMPSTATE
    echo "			type ENUMERATED" >> $TEMPSTATE
    echo "			count 1" >> $TEMPSTATE
    echo "			item.0 'Line In'" >> $TEMPSTATE
    echo "			item.1 Mic" >> $TEMPSTATE
    echo "		}" >> $TEMPSTATE
    echo "	}" >> $TEMPSTATE
    echo "}" >> $TEMPSTATE
    sudo sh -c "cp -f $TEMPSTATE /boot/crankshaft/alsactl.firstinit"
}


remove_ssh_message
relay_config
power_config
set_wallpaper
# rtc "ds3231" "$3"
# audio_audioinjector "wm8731-audio"
# audio_audioinjector_controls
# install_services
# activate_services
