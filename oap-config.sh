#!/bin/bash

# Activate SSH root
function remove_ssh_message() {
    sudo rm -f /etc/profile.d/sshpwd.sh
    sudo rm -f /etc/xdg/lxsession/LXDE-pi/sshpwd.sh
}

# Set Wallpaper
function set_wallpaper() {
    install -m 644 /boot/OAP-Config/wallpaper.png                      "/home/pi"
    install -m 644 /boot/OAP-Config/wallpaper.png                      "/usr/share/plymouth/themes/pix/splash.png"
    sudo sed -i "s/wallpaper=.*/wallpaper=\/home\/pi\/wallpaper.png/g" /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
}

# Remove unwanted OAP apps
function config_oap() {
    install -m 644 /boot/OAP-Config/config/openauto_androidauto.ini             "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_applications.ini            "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_controller_service.ini      "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_license.dat                 "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_system.ini                  "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_tos.dat                     "/home/pi"
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

    install -d "/opt/OAP"
    install -m 755 /boot/OAP-Config/scripts/service_user_startup.sh             "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/service_gpio_shutdown.sh            "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/obd-keys.py                         "/opt/OAP/"
    # install -m 755 /boot/OAP-Config/scripts/service_hwclock.sh                  "/opt/OAP/"
    # install -m 755 /boot/OAP-Config/scripts/service_custombrightness.sh         "/opt/OAP/"
}

# Activate services
function activate_services() {
    systemctl enable user_startup.service
    systemctl enable gpio_shutdown.service
    # systemctl enable hwclock-load.service
    # systemctl enable custombrightness.service
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
function activate_rtc() {
    activate_i2c
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i 's/^# RTC Setup.*//' /boot/config.txt
    sudo sed -i '/dtoverlay=i2c-rtc/d' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# RTC Setup' >> /boot/config.txt"
    sudo sh -c "echo 'dtoverlay=i2c-rtc,ds3231' >> /boot/config.txt"
    # sudo systemctl enable hwclock-load.service >/dev/null 2>&1
    # sudo systemctl daemon-reload
	# sudo timedatectl set-timezone "$(cat /etc/timezone)"
}

function activate_i2c() {
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sed -i '/dtoverlay=i2c_arm=/d' /boot/config.txt
    sudo sed -i 's/^# I2C Bus.*//' /boot/config.txt
    sudo sed -i '/./,/^$/!d' /boot/config.txt
    sudo sh -c "echo '' >> /boot/config.txt"
    sudo sh -c "echo '# I2C Bus' >> /boot/config.txt"
    sudo sh -c "echo 'dtoverlay=i2c_arm=on' >> /boot/config.txt"
}

remove_ssh_message
relay_config
power_config
set_wallpaper
config_oap
install_rearcam
# activate_rtc
install_services
activate_services
