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

# Remove unwanted OAP apps
function remove_apps() {
    install -m 644 /boot/OAP-Config/openauto_applications.ini                      "/home/pi"
}

# Install cam_overlay Rearcam
function install_rearcam() {
    install -d "/opt/OAP/cam_overlay"
    install -m 755 /boot/OAP-Config/cam_overlay/cam_overlay.bin                 "/opt/OAP/cam_overlay"
    install -m 755 /boot/OAP-Config/cam_overlay/overlay.png                     "/opt/OAP/cam_overlay"
    install -m 755 /boot/OAP-Config/cam_overlay/shader.frag                     "/opt/OAP/cam_overlay"
    install -m 755 /boot/OAP-Config/cam_overlay/shader.vert                     "/opt/OAP/cam_overlay"
    install -m 755 /boot/OAP-Config/cam_overlay/shader-YUYV.frag                "/opt/OAP/cam_overlay"
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
    install -m 755 /boot/OAP-Config/scripts/obd-keys.py                         "/opt/OAP/"
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
    sudo sh -c "echo 'dtoverlay=audioinjector-wm8731-audio' >> /boot/config.txt"
#    sudo sh -c "echo 'dtparam=i2s=on' >> /boot/config.txt"
    alsactl --file /boot/OAP-Config/AudioInjector-RCA.state restore
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

remove_ssh_message
relay_config
power_config
set_wallpaper
remove_apps
install_rearcam
# audio_audioinjector
# rtc "ds3231" "$3"
install_services
activate_services
