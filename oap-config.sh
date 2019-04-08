#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please use sudo."
  exit
fi

# Desktop icons
function set_icons() {
    rm -f /home/pi/Desktop/openauto

    install -m 644 /boot/OAP-Config/desktop/openauto.png        "/home/pi/icons"
    install -m 644 /boot/OAP-Config/desktop/reboot.png          "/home/pi/icons"

    install -m 644 /boot/OAP-Config/desktop/openauto.desktop    "/home/pi/Desktop"
    install -m 644 /boot/OAP-Config/desktop/reboot.desktop      "/home/pi/Desktop"
}

# Activate SSH root
function remove_ssh_message() {
    rm -f /etc/profile.d/sshpwd.sh
    rm -f /etc/xdg/lxsession/LXDE-pi/sshpwd.sh
}

# Auto hide taskbar
function hide_taskbar() {
    sed -i 's/^autohide=0/autohide=1/' /home/pi/.config/lxpanel/LXDE-pi/panels/panel
    sed -i 's/^heightwhenhidden=2/heightwhenhidden=0/' /home/pi/.config/lxpanel/LXDE-pi/panels/panel
    sed -i 's/^@point-rpi//' /home/pi/.config/lxsession/LXDE-pi/autostart
}

# RPI init (set country, language and timezone)
function rpi_init() {
    # Remove piwiz
    apt-get remove piwiz -y
    # WiFi
    wpa_cli -i wlan0 set country NL
    iw reg set NL
    wpa_cli -i wlan0 save_config

    # Timezone
    rm /etc/timezone
    sh -c "echo 'Europe/Amsterdam' >> /etc/timezone"
    rm /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata

    # Locale
    sed -i 's/^# nl_NL.UTF-8 UTF-8/nl_NL.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    LC_ALL=nl_NL.UTF-8 LANG=nl_NL.UTF-8 LANGUAGE=nl_NL.UTF-8 update-locale LC_ALL=nl_NL.UTF-8 LANG=nl_NL.UTF-8 LANGUAGE=nl_NL.UTF-8
}

# Set Wallpaper
function set_wallpaper() {
    install -m 644 /boot/OAP-Config/wallpaper.png                      "/home/pi"
    install -m 644 /boot/OAP-Config/wallpaper.png                      "/usr/share/plymouth/themes/pix/splash.png"
    sed -i "s/wallpaper=.*/wallpaper=\/home\/pi\/wallpaper.png/g" /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
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
    install -m 644 /boot/OAP-Config/services/DABBoard.service                    "/etc/systemd/system/"

    install -d "/opt/OAP"
    install -m 755 /boot/OAP-Config/scripts/service_user_startup.sh             "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/service_gpio_shutdown.sh            "/opt/OAP/"
    install -m 755 /boot/OAP-Config/DABBoard/radio_cli                          "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/DABBoard.sh                         "/opt/OAP/"
}

# Activate services
function activate_services() {
    systemctl enable user_startup.service
    systemctl enable gpio_shutdown.service
}

# Shutdown functions
function relay_config() {
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^dtoverlay=gpio-poweroff.*//' /boot/config.txt
    sed -i 's/^# GPIO triggerd poweroff.*//' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# GPIO triggerd poweroff' >> /boot/config.txt"
    sh -c "echo 'dtoverlay=gpio-poweroff,gpiopin=5,active_low="y"' >> /boot/config.txt"
}

# Power settings
function power_config() {
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^max_usb_current.*//' /boot/config.txt
    sed -i 's/^# Custom power settings.*//' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# Custom power settings' >> /boot/config.txt"
    sh -c "echo 'max_usb_current=1' >> /boot/config.txt"
}

# uGreen DABBoard
function activate_dab() {
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^# DAB Setup.*//' /boot/config.txt
    sed -i 's/^dtparam=spi=on.*//' /boot/config.txt
    sed -i 's/^dtparam=i2s=on.*//' /boot/config.txt
    sed -i 's/^dtoverlay=audiosense-pi.*//' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# DAB Setup' >> /boot/config.txt"
    sh -c "echo 'dtparam=spi=on' >> /boot/config.txt"
    sh -c "echo 'dtparam=i2s=on' >> /boot/config.txt"
    sh -c "echo 'dtoverlay=audiosense-pi' >> /boot/config.txt"
}

# RTC functions
function activate_rtc() {
    activate_i2c
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^# RTC Setup.*//' /boot/config.txt
    sed -i '/dtoverlay=i2c-rtc/d' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# RTC Setup' >> /boot/config.txt"
    sh -c "echo 'dtoverlay=i2c-rtc,ds3231' >> /boot/config.txt"
    # systemctl enable hwclock-load.service >/dev/null 2>&1
    # systemctl daemon-reload
	# timedatectl set-timezone "$(cat /etc/timezone)"
}

function activate_i2c() {
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i '/dtoverlay=i2c_arm=/d' /boot/config.txt
    sed -i 's/^# I2C Bus.*//' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# I2C Bus' >> /boot/config.txt"
    sh -c "echo 'dtoverlay=i2c_arm=on' >> /boot/config.txt"
}

function set_permissions() {
    chown -R pi:pi /home/pi
}

killall autoapp
rpi_init
remove_ssh_message
relay_config
power_config
activate_dab
# activate_rtc
set_wallpaper
set_icons
config_oap
install_rearcam
install_services
activate_services
set_permissions
