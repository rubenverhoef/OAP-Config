#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please use sudo."
  exit
fi

# Update the system
function update_system() {
    apt-get update -y
    apt-get dist-upgrade -y
    apt full-upgrade -y
    apt-get autoremove -y
}

# configure bootloader to poweroff
function config_bootloader() {
    # see https://github.com/raspberrypi/rpi-eeprom/tree/master/firmware/critical for latest
    apt install rpi-eeprom -y
    cp /lib/firmware/raspberrypi/bootloader/critical/pieeprom-2019-09-10.bin /home/pi/pieeprom.bin
    rpi-eeprom-config /home/pi/pieeprom.bin > /home/pi/bootconf.txt
    
    sed -i 's/^WAKE_ON_GPIO=1/WAKE_ON_GPIO=0/' /home/pi/bootconf.txt
    sed -i 's/^POWER_OFF_ON_HALT=0/POWER_OFF_ON_HALT=1/' /home/pi/bootconf.txt

    rpi-eeprom-config --out /home/pi/pieeprom-new.bin --config /home/pi/bootconf.txt /home/pi/pieeprom.bin
    rpi-eeprom-update -d -f /home/pi/pieeprom-new.bin
    rm -f /home/pi/pieeprom-new.bin
    rm -f /home/pi/pieeprom.bin
    rm -f /home/pi/bootconf.txt
}

# Desktop icons
function set_icons() {
    apt-get install xdotool
    rm -f /home/pi/Desktop/openauto

    install -m 644 /boot/OAP-Config/desktop/openauto.png        "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/desktop/reboot.png          "/home/pi/.openauto/icons"

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
    sed -i 's/^  autohide=0/  autohide=1/' /home/pi/.config/lxpanel/LXDE-pi/panels/panel
    sed -i 's/^  heightwhenhidden=2/  heightwhenhidden=0/' /home/pi/.config/lxpanel/LXDE-pi/panels/panel
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
    install -m 644 /boot/OAP-Config/desktop/wallpaper.png   "/home/pi"
    sed -i "s/wallpaper=.*/wallpaper=\/home\/pi\/wallpaper.png/g" /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
}

# Set custom desktop settings
function custom_desktop() {
    install -d "/home/pi/.config/lxsession/LXDE-pi"
    cp /etc/xdg/lxsession/LXDE-pi/autostart /home/pi/.config/lxsession/LXDE-pi/autostart
}

# Set Splash boot screen
function set_splash() {
    cp /boot/OAP-Config/desktop/wallpaper.png /usr/share/plymouth/themes/pix/splash.png     
    install -m 644 /boot/OAP-Config/splash/splash1.h264   "/usr/share/openautopro"
    install -m 644 /boot/OAP-Config/splash/splash2.h264   "/usr/share/openautopro"
}

# Remove unwanted OAP apps
function config_oap() {
    install -m 644 /boot/OAP-Config/config/openauto_applications.ini        "/home/pi/.openauto/config"
    install -m 644 /boot/openauto_license.dat                               "/home/pi/.openauto"
    install -m 644 /boot/OAP-Config/config/openauto_system.ini              "/home/pi/.openauto/config"
    install -m 644 /boot/OAP-Config/config/openauto_terms_of_service.dat    "/home/pi/.openauto"
    install_radio_icons
}

# Copy all the radio icons
install_radio_icons() {
    install -m 644 /boot/OAP-Config/DAB/icons/skyradio.png          "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/skyhits.png           "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/qmusic-nonstop.png    "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/qmusic.png            "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/538.png               "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/538top50.png          "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/slam.png              "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/veronica.png          "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/radio10.png           "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/sublime.png           "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/100nl.png             "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/radio1.png            "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/radio2.png            "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/3fm.png               "/home/pi/.openauto/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/funx.png              "/home/pi/.openauto/icons"
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
    apt install inotify-tools -y
    install -m 644 /boot/OAP-Config/services/OAP_startup.service                "/etc/systemd/system/"
    install -m 644 /boot/OAP-Config/services/lightsensor.service                "/etc/systemd/system/"
    install -m 644 /boot/OAP-Config/services/dabboard.service                   "/etc/systemd/system/"

    install -d "/opt/OAP"
    install -m 755 /boot/OAP-Config/scripts/obd-keys.py                         "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/service_lightsensor.py              "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/service_OAP_startup.sh              "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/OBD_startup.sh                      "/opt/OAP/"
    install -m 755 /boot/OAP-Config/DAB/radio_cli                               "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/TuneDAB.sh                          "/opt/OAP/"
    install -m 755 /boot/OAP-Config/desktop/OAP_startup.sh                      "/opt/OAP/"
}

# Activate services
function activate_services() {
    systemctl enable OAP_startup.service
    systemctl enable lightsensor.service
    systemctl enable dabboard.service
    sed -i '/@bash \/opt\/OAP\/OBD_startup.sh/d' /home/pi/.config/lxsession/LXDE-pi/autostart
    sh -c "echo '@bash /opt/OAP/OBD_startup.sh' >> /home/pi/.config/lxsession/LXDE-pi/autostart"
}

# Update wiring pi (RPI4 needs 2.52)
function update_wiringpi() {
    wget -q https://project-downloads.drogon.net/wiringpi-latest.deb -O /tmp/wiringpi.deb
    sudo dpkg -i /tmp/wiringpi.deb
}

# Install additional python packages
function install_python_packages() {
    pip3 install astral
    pip3 install PyUserInput
    cd /boot/OAP-Config/python-OBD && python3 /boot/OAP-Config/python-OBD/setup.py install
}

# uGreen DABBoard
function activate_dab() {
    apt-get install libncurses5 -y
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
    /usr/bin/python3 /usr/local/bin/bwsrtc
}

function activate_i2c() {
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i '/dtparam=i2c_arm=/d' /boot/config.txt
    sed -i 's/^# I2C Bus.*//' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# I2C Bus' >> /boot/config.txt"
    sh -c "echo 'dtparam=i2c_arm=on' >> /boot/config.txt"
}

function set_permissions() {
    chown -R pi:pi /home/pi
}

function activate_gps() {
    # Remove UART from console
    sed -i 's/ console=serial0,115200//g' /boot/cmdline.txt

    # Config.txt UART
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^# GPS Setup.*//' /boot/config.txt
    sed -i '/enable_uart=1/d' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# GPS Setup' >> /boot/config.txt"
    sh -c "echo 'enable_uart=1' >> /boot/config.txt"

    # GPSD, use UART
    sed -i 's/^USBAUTO=.*/USBAUTO="false"/' /etc/default/gpsd
    sed -i 's/^DEVICES=.*/DEVICES="\/dev\/serial0"/' /etc/default/gpsd
    sed -i 's/^GPSD_OPTIONS=.*/GPSD_OPTIONS="-n"/' /etc/default/gpsd
}

function phone_hotspot_config() {
    # config OnePlus 3T hotspot to get internet on the RPI

    if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
        sed -i '/./,/^$/!d' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i 's/^network=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i 's/^[[:space:]]*ssid=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i 's/^[[:space:]]*psk=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i 's/^[[:space:]]*#psk=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i 's/^[[:space:]]*key_mgmt=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i 's/^}*//' /etc/wpa_supplicant/wpa_supplicant.conf
        sed -i '/./,/^$/!d' /etc/wpa_supplicant/wpa_supplicant.conf
    else
        sh -c "echo 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev' > /etc/wpa_supplicant/wpa_supplicant.conf"
        sh -c "echo 'update_config=1' >> /etc/wpa_supplicant/wpa_supplicant.conf"
        sh -c "echo 'country=NL' >> /etc/wpa_supplicant/wpa_supplicant.conf"
        sh -c "echo '' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    fi

    sh -c "echo 'network={' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '    ssid=\"OnePlus 3T Ruben\"' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '    psk=\"1+3TRuben\"' >> /etc/wpa_supplicant/wpa_supplicant.conf" # Not secret
    sh -c "echo '    key_mgmt=WPA-PSK' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '}' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '' >> /etc/wpa_supplicant/wpa_supplicant.conf"
}

function activate_watchdog() {
    # config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^# Watchdog.*//' /boot/config.txt
    sed -i '/dtparam=watchdog=on/d' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# Watchdog' >> /boot/config.txt"
    sh -c "echo 'dtparam=watchdog=on' >> /boot/config.txt"
}

function activate_ds18b20() {
    # config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sed -i 's/^# DS18B20 Temperature Sensor.*//' /boot/config.txt
    sed -i '/dtoverlay=w1-gpio/d' /boot/config.txt
    sed -i '/./,/^$/!d' /boot/config.txt
    sh -c "echo '' >> /boot/config.txt"
    sh -c "echo '# DS18B20 Temperature Sensor' >> /boot/config.txt"
    sh -c "echo 'dtoverlay=w1-gpio' >> /boot/config.txt"
}

killall autoapp
update_system
config_bootloader
rpi_init
remove_ssh_message
custom_desktop
# hide_taskbar # better to show taskbar to easy access to wifi/bt settings
install_python_packages
update_wiringpi
activate_dab
activate_rtc
activate_gps
activate_watchdog
set_wallpaper
set_splash
set_icons
config_oap
install_rearcam
install_services
activate_services
phone_hotspot_config
activate_ds18b20
set_permissions
