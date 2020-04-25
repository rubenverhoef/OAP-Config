#!/usr/bin/python3

import os, sys, math, time, subprocess

from pykeyboard import PyKeyboard # import for emulating keyboard presses
import RPi.GPIO as GPIO

import obd #import for reading/sending obd messages
from obd import OBDCommand, OBDStatus
from obd.protocols import ECU
from obd.utils import bytes_to_int
import obd.decoders as d

reverseGPIO = 27
# GPIO stuff
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(reverseGPIO, GPIO.OUT)
GPIO.output(reverseGPIO, GPIO.LOW)

keyboard = PyKeyboard()

class OBDStruct:
    def __init__(self, bitSelect, isPressing, button):
        self.bitSelect  = bitSelect
        self.isPressing = isPressing
        self.button     = button

    def pressButton(self):
        keyboard.press_key(self.button)

    def releaseButton(self):
        keyboard.release_key(self.button)

    def TuneDAB(self):
        os.chdir("/opt/OAP/")
        if(self.button is "0"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-k"]) # Turn off DAB
        elif(self.button is "1"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "4", "-e", "34820", "-f", "28"])
        elif(self.button is "2"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "2", "-e", "34818", "-f", "28"])
        elif(self.button is "3"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "2", "-e", "33283", "-f", "33"])
        elif(self.button is "4"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "10", "-e", "33736", "-f", "28"])
        elif(self.button is "5"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "1", "-e", "33735", "-f", "28"])
        elif(self.button is "6"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "5", "-e", "33734", "-f", "28"])
        elif(self.button is "7"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "11", "-e", "33445", "-f", "28"])
        elif(self.button is "8"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "7", "-e", "33761", "-f", "28"])
        elif(self.button is "9"):
            subprocess.Popen(["sudo", "./TuneDAB.sh", "-c", "17", "-e", "33746", "-f", "28"])
            
    def revCamOn(self):
        GPIO.output(reverseGPIO, GPIO.HIGH)
        keyboard.tap_key(keyboard.function_keys[6])
        time.sleep(0.1)
        os.chdir("/opt/OAP/cam_overlay/")
        subprocess.Popen(["./cam_overlay.bin", "-s", "-d", "/dev/v4l/by-id/usb-fushicai_usbtv007_300000000002-video-index0"])

    def revCamOff(self):
        GPIO.output(reverseGPIO, GPIO.LOW)
        keyboard.tap_key(keyboard.function_keys[6])
        time.sleep(0.1)
        subprocess.Popen(["killall", "cam_overlay.bin"])

revCMD      = b"223B54"
revHeader   = b'000726'
revBytes    = 2
revBase     = 0x623B540000
revGear     = OBDStruct((0x623B540001 ^ revBase), False, None)

rev = OBDCommand("Reverse Gear",
               "Decode Reverse Gear Command",
               revCMD,
               (3 + revBytes),
               d.drop,
               ECU.ALL,
               True,
               revHeader)

def rev_clb(data):
    try:
        data = bytes_to_int(data.messages[0].data[3:])
        if(revGear.bitSelect & data):
            if(revGear.isPressing is False):
                revGear.isPressing = True
                revGear.revCamOn()
        elif(revGear.isPressing is True):
            revGear.isPressing = False
            revGear.revCamOff()
        return
    except:
        pass
    return

swCMD     = b"22833C"
swHeader  = b'0007A5'
swBytes   = 1
swBase    = 0x62833C00
# swVolUp   = OBDStruct((0x62833C80 ^ swBase), False, None)
# swVolDown = OBDStruct((0x62833C40 ^ swBase), False, None)
swVoice   = OBDStruct((0x62833C08 ^ swBase), False, "m")       # Voice Command
swNext    = OBDStruct((0x62833C04 ^ swBase), False, "n")      # Next
swPrev    = OBDStruct((0x62833C02 ^ swBase), False, "v")      # Previous
swM       = OBDStruct((0x62833C01 ^ swBase), False, keyboard.enter_key) # Enter

swButtons   = [swVoice, swNext, swPrev, swM]

sw = OBDCommand("Steering Wheel",
               "Decode SW Commands",
               swCMD,
               (3 + swBytes),
               d.drop,
               ECU.ALL,
               True,
               swHeader)

def sw_clb(data):
    try:
        data = bytes_to_int(data.messages[0].data[3:])
        for c, swButton in enumerate(swButtons, 1):
            if(swButton.bitSelect & data):
                if(swButton.isPressing is False):
                    swButton.isPressing = True
                    swButton.pressButton()
            elif(swButton.isPressing is True):
                swButton.isPressing = False
                swButton.releaseButton()
    except:
        pass
    return

dpadCMD	   = b"22412C"
dpadHeader = b'0007A5'
dpadBytes  = 1
dpadBase   = 0x62412C00
# dpadLeft    = OBDStruct((0x62412C04 ^ dpadBase), False, "1")
dpadRight   = OBDStruct((0x62412C02 ^ dpadBase), False, keyboard.left_key)    # Hamburger Menu
dpadUp      = OBDStruct((0x62412C10 ^ dpadBase), False, "1")             # Wheel Left
dpadDown    = OBDStruct((0x62412C08 ^ dpadBase), False, "2")             # Wheel Right

dpadButtons   = [dpadUp, dpadDown]

dpad = OBDCommand("DPAD",
               "Decode DPAD Commands",
               dpadCMD,
               (3 + dpadBytes),
               d.drop,
               ECU.ALL,
               True,
               dpadHeader)

def dpad_clb(data):
    try:
        data = bytes_to_int(data.messages[0].data[3:])
        for c, dpadButton in enumerate(dpadButtons, 1):
            if(dpadButton.bitSelect & data):
                if(dpadButton.isPressing is False):
                    dpadButton.isPressing = True
                    dpadButton.pressButton()
            elif(dpadButton.isPressing is True):
                dpadButton.isPressing = False
                dpadButton.releaseButton()
    except:
        pass
    return

keyCMD     = b"228051"
keyHeader  = b'0007A5'
keyBytes   = 4
keyBase    = 0x62805100000000
key0       = OBDStruct((0x62805100000400 ^ keyBase), False, "0")           # Stop DAB radio
key1       = OBDStruct((0x62805100000800 ^ keyBase), False, "1")           # Qmusic non-stop
key2       = OBDStruct((0x62805100001000 ^ keyBase), False, "2")           # 538Top50
key3       = OBDStruct((0x62805100002000 ^ keyBase), False, "3")           # 3FM
key4       = OBDStruct((0x62805100004000 ^ keyBase), False, "4")           # Qmusic
key5       = OBDStruct((0x62805100008000 ^ keyBase), False, "5")           # 538
key6       = OBDStruct((0x62805100000001 ^ keyBase), False, "6")           # Sky Radio
key7       = OBDStruct((0x62805100000002 ^ keyBase), False, "7")           # Slam!
key8       = OBDStruct((0x62805100000004 ^ keyBase), False, "8")           # Veronica
key9       = OBDStruct((0x62805100000008 ^ keyBase), False, "9")           # Radio10
keyStar    = OBDStruct((0x62805100000010 ^ keyBase), False, keyboard.down_key)  # Menu Down
keyHash    = OBDStruct((0x62805100000020 ^ keyBase), False, keyboard.up_key)    # Menu Up
keyInfo    = OBDStruct((0x62805140000000 ^ keyBase), False, keyboard.left_key)  # Hamburger Menu
# keyReject  = OBDStruct((0x62805100040000 ^ keyBase), False, "left arrow")  # Hamburger Menu
keyNext    = OBDStruct((0x62805100080000 ^ keyBase), False, "n")           # Next
keyPrev    = OBDStruct((0x62805100020000 ^ keyBase), False, "v")           # Previous
keyOK      = OBDStruct((0x62805100200000 ^ keyBase), False, keyboard.enter_key)      # Enter
# keyLL      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet # Map
# keyLR      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, "p") # don't logged yet # Phone
# keyRL      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, "h") # don't logged yet # Home
# keyRR      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet # Music
keyAUX     = OBDStruct((0x62805110000000 ^ keyBase), False, "b")           # Play/Pause
# keyTA      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet
# keyMusic   = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet
# keyCD      = OBDStruct((0x62805108000000 ^ keyBase), False, None)
# keyRadio   = OBDStruct((0x62805102000000 ^ keyBase), False, None)
# keyPhone   = OBDStruct((0x62805100000100 ^ keyBase), False, None)
# keyMenu    = OBDStruct((0x62805100800000 ^ keyBase), False, None)
# keyVolUp   = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet
# keyVolDown = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet

keyButtons  = [keyStar, keyHash, keyInfo, keyNext, keyPrev, keyOK, keyAUX]
DABButtons  = [key0, key1, key2, key3, key4, key5, key6, key7, key8, key9]

key = OBDCommand("Radio Keys",
               "Decode Radio Keys",
               keyCMD,
               (3 + keyBytes),
               d.drop,
               ECU.ALL,
               True,
               keyHeader)

def key_clb(data):
    try:
        data = bytes_to_int(data.messages[0].data[3:])
        for c, keyButton in enumerate(keyButtons, 1):
            if(keyButton.bitSelect & data):
                if(keyButton.isPressing is False):
                    keyButton.isPressing = True
                    keyButton.pressButton()
            elif(keyButton.isPressing is True):
                keyButton.isPressing = False
                keyButton.releaseButton()
        for c, keyButton in enumerate(DABButtons, 1):
            if(keyButton.bitSelect & data):
                if(keyButton.isPressing is False):
                    keyButton.isPressing = True
                    keyButton.TuneDAB()
            elif(keyButton.isPressing is True):
                keyButton.isPressing = False
    except:
        pass
    return

#obd.logger.setLevel(obd.logging.DEBUG)
reconnect = True
errorcnt = 0

while(True):
    time.sleep(1)
    if reconnect == True:
        reconnect = False
        connection = obd.OBD("/dev/ttyUSB0", protocol = "B")

        connection.supported_commands.add(rev)
        connection.supported_commands.add(sw)
        connection.supported_commands.add(dpad)
        connection.supported_commands.add(key)

    while(connection.status() == OBDStatus.CAR_CONNECTED):
        try:
            rev_clb(connection.query(rev))
        except:
            pass

        for x in range(5):
            try:
                sw_clb(connection.query(sw))
            except:
                pass

            try:
                dpad_clb(connection.query(dpad))
            except:
                pass

            try:
                key_clb(connection.query(key))
            except:
                pass
    if connection.status() == OBDStatus.NOT_CONNECTED:
        errorcnt += 1
        if errorcnt >= 10:
            reconnect = True
            connection.close()
