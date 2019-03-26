#!/usr/bin/python3

import os, sys, math, time, subprocess

sys.path.append(os.path.join(os.path.dirname(__file__), "PyUserInput"))
sys.path.append(os.path.join(os.path.dirname(__file__), "python-xlib")) # needed for PyUserInput
sys.path.append(os.path.join(os.path.dirname(__file__), "obd"))
sys.path.append(os.path.join(os.path.dirname(__file__), "pint")) # needed for OBD

from pykeyboard import PyKeyboard # import for emulating keyboard presses

import obd #import for reading/sending obd messages
from obd import OBDCommand
from obd.protocols import ECU
from obd.utils import bytes_to_int
import obd.decoders as d

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

    def revCamOn(self):
        os.chdir("/opt/OAP/cam_overlay/")
        subprocess.Popen(["./cam_overlay.bin", "-d", "/dev/v4l/by-id/usb-fushicai_usbtv007_300000000002-video-index0"])

    def revCamOff(self):
        subprocess.Popen(["killall", "cam_overlay.bin"])
    
    def ModeNight(self):
        keyboard.tap_key(keyboard.function_keys[2])
        subprocess.Popen(["gpio", "-g", "pwm", "12", "800"])

    def ModeDay(self):
        keyboard.tap_key(keyboard.function_keys[2])
        subprocess.Popen(["gpio", "-g", "pwm", "12", "0"])

revCMD      = b"223B54"
revHeader   = b'000726'
revBytes    = 2
revBase     = 0x623B540000
revGear     = OBDStruct((0x623B540001 ^ revBase), None, None)

rev = OBDCommand("Reverse Gear",
               "Decode Reverse Gear Command",
               revCMD,
               (3 + revBytes),
               d.drop,
               ECU.ALL,
               True,
               revHeader)

def rev_clb(data):
    data = bytes_to_int(data.messages[0].data[3:])
    if(revGear.bitSelect & data):
        if(revGear.isPressing is False):
            revGear.isPressing = True
            revGear.revCamOn()
    elif(revGear.isPressing is True):
        revGear.isPressing = False
        revGear.revCamOff()
    return

lightCMD    = b"227151"
lightHeader = b'000726'
lightBytes  = 2
lightBase   = 0x6271510000
lightBeam   = OBDStruct((0x6271510008 ^ lightBase), None, None)

light = OBDCommand("Light status",
               "Decode Light status Command",
               lightCMD,
               (3 + lightBytes),
               d.drop,
               ECU.ALL,
               True,
               lightHeader)

def light_clb(data):
    data = bytes_to_int(data.messages[0].data[3:])
    if(lightBeam.bitSelect & data):
        if(lightBeam.isPressing is False):
            lightBeam.isPressing = True
            lightBeam.ModeNight()
    elif(lightBeam.isPressing is True):
        lightBeam.isPressing = False
        lightBeam.ModeDay()
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
swM       = OBDStruct((0x62833C01 ^ swBase), False, "return") # Enter

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
    data = bytes_to_int(data.messages[0].data[3:])
    for c, swButton in enumerate(swButtons, 1):
        if(swButton.bitSelect & data):
            if(swButton.isPressing is False):
                swButton.isPressing = True
                swButton.pressButton()
        elif(swButton.isPressing is True):
            swButton.isPressing = False
            swButton.releaseButton()
    return

dpadCMD	   = b"22412C"
dpadHeader = b'0007A5'
dpadBytes  = 1
dpadBase   = 0x62412C00
# dpadLeft    = OBDStruct((0x62412C04 ^ keyBase), False, "1")
dpadRight   = OBDStruct((0x62412C02 ^ keyBase), False, "left arrow")    # Hamburger Menu
dpadUp      = OBDStruct((0x62412C10 ^ keyBase), False, "1")             # Wheel Left
dpadDown    = OBDStruct((0x62412C08 ^ keyBase), False, "2")             # Wheel Right   
 
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
    data = bytes_to_int(data.messages[0].data[3:])
    for c, dpadButton in enumerate(dpadButtons, 1):
        if(dpadButton.bitSelect & data):
            if(dpadButton.isPressing is False):
                dpadButton.isPressing = True
                dpadButton.pressButton()
        elif(dpadButton.isPressing is True):
            dpadButton.isPressing = False
            dpadButton.releaseButton()
    return
   
keyCMD     = b"228051"
keyHeader  = b'0007A5'
keyBytes   = 4
keyBase    = 0x62805100000000
# key0       = OBDStruct((0x62805100000400 ^ keyBase), False, "0")           # Stop DAB radio
# key1       = OBDStruct((0x62805100000800 ^ keyBase), False, "1")           # Sky Radio
# key2       = OBDStruct((0x62805100001000 ^ keyBase), False, "2")           # Sky Rdaio Hits
# key3       = OBDStruct((0x62805100002000 ^ keyBase), False, "3")           # Qmusic non-stop
# key4       = OBDStruct((0x62805100004000 ^ keyBase), False, "4")           # Qmusic
# key5       = OBDStruct((0x62805100008000 ^ keyBase), False, "5")           # 538
# key6       = OBDStruct((0x62805100000001 ^ keyBase), False, "6")           # 538Top50
# key7       = OBDStruct((0x62805100000002 ^ keyBase), False, "7")           # Slam!
# key8       = OBDStruct((0x62805100000004 ^ keyBase), False, "8")           # Veronica
# key9       = OBDStruct((0x62805100000008 ^ keyBase), False, "9")           # Radio10
keyStar    = OBDStruct((0x62805100000010 ^ keyBase), False, "escape")      # Esc
keyHash    = OBDStruct((0x62805100000020 ^ keyBase), False, "escape")      # Esc
keyInfo    = OBDStruct((0x62805140000000 ^ keyBase), False, "left arrow")  # Hamburger Menu
keyReject  = OBDStruct((0x62805100040000 ^ keyBase), False, "left arrow")  # Hamburger Menu
keyNext    = OBDStruct((0x62805100080000 ^ keyBase), False, "n")           # Next
keyPrev    = OBDStruct((0x62805100020000 ^ keyBase), False, "v")           # Previous
keyOK      = OBDStruct((0x62805100200000 ^ keyBase), False, "return")      # Enter
# keyLL      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet # Map
# keyLR      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, "p") # don't logged yet # Phone
# keyRL      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, "h") # don't logged yet # Home
# keyRR      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet # Music
keyAUX     = OBDStruct((0x62805110000000 ^ keyBase), False, "x")           # Play
# keyTA      = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet
# keyMusic   = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet
# keyCD      = OBDStruct((0x62805108000000 ^ keyBase), False, None)
# keyRadio   = OBDStruct((0x62805102000000 ^ keyBase), False, None)
# keyPhone   = OBDStruct((0x62805100000100 ^ keyBase), False, None)
# keyMenu    = OBDStruct((0x62805100800000 ^ keyBase), False, None)
# keyVolUp   = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet
# keyVolDown = OBDStruct((0x628051FFFFFFFF ^ keyBase), False, None) # don't logged yet

keyButtons  = [keyStar, keyHash, keyInfo, keyNext, keyPrev, keyOK, keyAUX]

key = OBDCommand("Radio Keys",
               "Decode Radio Keys",
               keyCMD,
               (3 + keyBytes),
               d.drop,
               ECU.ALL,
               True,
               keyHeader)

def key_clb(data):
    data = bytes_to_int(data.messages[0].data[3:])
    for c, keyButton in enumerate(keyButtons, 1):
        if(keyButton.bitSelect & data):
            if(keyButton.isPressing is False):
                keyButton.isPressing = True
                keyButton.pressButton()
        elif(keyButton.isPressing is True):
            keyButton.isPressing = False
            keyButton.releaseButton()
    return

#obd.logger.setLevel(obd.logging.DEBUG)

connection = obd.OBD("COM1", protocol = "B")

connection.supported_commands.add(rev)
connection.supported_commands.add(light)
connection.supported_commands.add(sw)
connection.supported_commands.add(dpad)
connection.supported_commands.add(key)

while(True):
    rev_clb(connection.query(rev))
    light_clb(connection.query(light))
    sw_clb(connection.query(sw))
    dpad_clb(connection.query(dpad))
    key_clb(connection.query(key))
    #time.sleep(0.01)
    