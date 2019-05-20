#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please use sudo."
  exit
fi

# Update the system
function update_system() {
    sudo apt-get update -y
    sudo apt-get dist-upgrade -y
    sudo rpi-update
    sudo apt-get autoremove -y
}

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
    install -m 644 /boot/OAP-Config/desktop/wallpaper.png   "/usr/share/plymouth/themes/pix/splash.png"
    sed -i "s/wallpaper=.*/wallpaper=\/home\/pi\/wallpaper.png/g" /home/pi/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
}

# Remove unwanted OAP apps
function config_oap() {
    install -m 644 /boot/OAP-Config/config/openauto_applications.ini        "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_controller_service.ini  "/home/pi"
    install -m 644 /boot/openauto_license.dat                               "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_system.ini              "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_tos.dat                 "/home/pi"
    install -m 644 /boot/OAP-Config/config/openauto_wifi_recent.ini         "/home/pi"
    install_radio_icons
}

# Copy all the radio icons
install_radio_icons() {
    install -m 644 /boot/OAP-Config/DAB/icons/skyradio.png          "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/skyhits.png           "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/qmusic-nonstop.png    "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/qmusic.png            "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/538.png               "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/538top50.png          "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/slam.png              "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/veronica.png          "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/radio10.png           "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/sublime.png           "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/100nl.png             "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/radio1.png            "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/radio2.png            "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/3fm.png               "/home/pi/icons"
    install -m 644 /boot/OAP-Config/DAB/icons/funx.png              "/home/pi/icons"
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
    install -m 644 /boot/OAP-Config/services/OAP_startup.service               "/etc/systemd/system/"

    install -d "/opt/OAP"
    install -m 755 /boot/OAP-Config/scripts/service_OAP_startup.sh              "/opt/OAP/"
    install -m 755 /boot/OAP-Config/OBD/OBD_startup.sh                          "/opt/OAP/"
    install -m 755 /boot/OAP-Config/DAB/radio_cli                               "/opt/OAP/"
    install -m 755 /boot/OAP-Config/DAB/TuneDAB.sh                              "/opt/OAP/"
    install -m 755 /boot/OAP-Config/scripts/start_watchdog                      "/opt/OAP/"
    install -m 755 /boot/OAP-Config/desktop/OAP_startup.sh                      "/opt/OAP/"
    install -m 755 /boot/OAP-Config/desktop/reboot.sh                           "/opt/OAP/"
}

# Activate services
function activate_services() {
    systemctl enable OAP_startup.service
    sed -i '/@bash \/opt\/OAP\/OBD_startup.sh/d' /home/pi/.config/lxsession/LXDE-pi/autostart
    sh -c "echo '@bash /opt/OAP/OBD_startup.sh' >> /home/pi/.config/lxsession/LXDE-pi/autostart"
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
    /usr/bin/python3 /usr/local/bin/bwsrtc
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
    sed -i 's/^USBAUTO="true"/USBAUTO="false"/' /etc/default/gpsd
    sed -i 's/^DEVICES=""/DEVICES="\/dev\/serial0"/' /etc/default/gpsd
    sed -i 's/^GPSD_OPTIONS=""/GPSD_OPTIONS="-n"/' /etc/default/gpsd
}

function install_raspap() {
    if [ ! -d "/etc/raspap" ]; then
        wget -q https://git.io/voEUQ -O /tmp/raspap && bash /tmp/raspap
    fi

    # set SSID, Pass
    sed -i 's/^ssid=.*/ssid=Ford\ Fiësta\ Ruben/' /etc/hostapd/hostapd.conf
    sed -i 's/^wpa_passphrase=.*/wpa_passphrase=FordFeestRuben/' /etc/hostapd/hostapd.conf

    # set static ip for android phones
    sed -i '/./,/^$/!d' /etc/dnsmasq.conf
    sed -i 's/^dhcp-host=.*//' /etc/dnsmasq.conf
    sed -i 's/^dhcp-host=.*//' /etc/dnsmasq.conf
    sed -i '/./,/^$/!d' /etc/dnsmasq.conf
    sh -c "echo 'dhcp-host=c0:ee:fb:e5:9f:d2,10.3.141.10' >> /etc/dnsmasq.conf" # OnePlus 3T Ruben
    sh -c "echo 'dhcp-host=50:55:27:ab:f4:1e,10.3.141.11' >> /etc/dnsmasq.conf" # Nexus 5X Anne

    # config OnePlus 3T hotspot to get internet on the RPI
    sed -i '/./,/^$/!d' /etc/wpa_supplicant/wpa_supplicant.conf
    sed -i 's/^network=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
    sed -i 's/^    ssid=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
    sed -i 's/^    psk=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
    sed -i 's/^    key_mgmt=.*//' /etc/wpa_supplicant/wpa_supplicant.conf
    sed -i 's/^}*//' /etc/wpa_supplicant/wpa_supplicant.conf
    sed -i '/./,/^$/!d' /etc/wpa_supplicant/wpa_supplicant.conf
    sh -c "echo 'network={' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '    ssid=\"OnePlus 3T Ruben\"' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '    psk=\"1+3TRuben\"' >> /etc/wpa_supplicant/wpa_supplicant.conf" # Not secret
    sh -c "echo '    key_mgmt=WPA-PSK' >> /etc/wpa_supplicant/wpa_supplicant.conf"
    sh -c "echo '}' >> /etc/wpa_supplicant/wpa_supplicant.conf"
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

killall autoapp
update_system
rpi_init
remove_ssh_message
hide_taskbar
relay_config
power_config
activate_dab
activate_rtc
activate_gps
set_wallpaper
set_icons
config_oap
install_rearcam
install_services
activate_services
install_raspap
activate_watchdog
set_permissions
