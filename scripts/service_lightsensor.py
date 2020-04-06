#!/usr/bin/python3 -u

import smbus
import os
import RPi.GPIO as GPIO
import subprocess
from time import sleep
import pytz
import astral
from astral import *
from datetime import *

# ---------------------------------
# the addresss of TSL2561 can be
# 0x29, 0x39 or 0x49
BUS = 1
TSL2561_ADDR = 0x39
daynight_gpio = 0
pwm_gpio = 12
TSL2561_CHECK_INTERVAL=0.5
PWM_MAX=1023
LUX_DARK_BR=50
LUX_FULL_BR=250
LUX_DAY=200
LUX_NIGHT=100
# ---------------------------------
# I2C Bus
i2cBus = smbus.SMBus(BUS)

# Sun data
time = Astral()
sun = time['Amsterdam'].sun(local=True, date=date.today())

# GPIO stuff
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(daynight_gpio, GPIO.OUT)
GPIO.output(daynight_gpio, GPIO.LOW)
os.system("gpio -g mode " + str(pwm_gpio) + " pwm")
br_a=-(PWM_MAX/(LUX_FULL_BR-LUX_DARK_BR))
br_b=(PWM_MAX+((PWM_MAX/(LUX_FULL_BR-LUX_DARK_BR)))*LUX_DARK_BR)

now = datetime.now(pytz.utc)
night = -1
if now >= sun['sunrise'] and now <= sun['sunset']: # Day
  night = False
  GPIO.output(daynight_gpio, GPIO.LOW)
elif not (now >= sun['sunrise'] and now <= sun['sunset']): # Night
  night = True
  GPIO.output(daynight_gpio, GPIO.HIGH)

Lux_Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
if not os.path.exists("/home/pi/TSL2561"):
  os.mkdir("/home/pi/TSL2561")
file = open("/home/pi/TSL2561/TSL2561-" + datetime.now().strftime("%d%m%Y-%H%M%S"), "w")

i2cBus.write_byte_data(TSL2561_ADDR, 0x80, 0x00)

try:
  while True:
    sleep (TSL2561_CHECK_INTERVAL)
    
    PowerState = i2cBus.read_byte_data(TSL2561_ADDR, 0x80)
    if PowerState & 0x03 is not 0x03:
      # Startup TSL2561
      # print("starting up")
      i2cBus.write_byte_data(TSL2561_ADDR, 0x80, 0x03)
      i2cBus.write_byte_data(TSL2561_ADDR, 0x81, 0x12)
      sleep (TSL2561_CHECK_INTERVAL)
    
    else:
      # print("read Cycle")

      # read global brightness
      Ambient = i2cBus.read_word_data(TSL2561_ADDR, 0xAC)
      # print ("Ambient: {}".format(Ambient))

      # read IR
      Infrared = i2cBus.read_word_data(TSL2561_ADDR, 0xAE)
      # print ("Infrared: {}".format(Infrared))

      if Infrared < 0xFFFF and Ambient < 0xFFFF: # Check if values are valid (not overflowed)
        # Calc factor Infrared/Ambient      
        if Ambient == 0:
          Ratio = 0
        else:
          Ratio = float(Infrared)/float(Ambient)

        # print ("Ratio: {}".format(Ratio))


        # Calc lux based on data sheet TSL2561T
        # T, FN, and CL Package
        if 0 < Ratio <= 0.50:
          Lux = 0.0304*float(Ambient) - 0.062*float(Ambient)*(Ratio**1.4)
        elif 0.50 < Ratio <= 0.61:
          Lux = 0.0224*float(Ambient) - 0.031*float(Infrared)
        elif 0.61 < Ratio <= 0.80:
          Lux = 0.0128*float(Ambient) - 0.0153*float(Infrared)
        elif 0.80 < Ratio <= 1.3:
          Lux = 0.00146*float(Ambient) - 0.00112*float(Infrared)
        else:
          Lux = 0

        if (Lux > LUX_FULL_BR):
          Lux = LUX_FULL_BR
      else:
        Lux = LUX_FULL_BR

      # print("Lux = {} | ".format(Lux))

      Lux_Array.append(Lux)
      Lux_Array.pop(0)
      total=0
      for x in Lux_Array:
        total=total+x
      avarage=total/10

      Level=int(round(br_a*avarage+br_b,0))
      if Level < 0:
        Level=0
      elif Level > PWM_MAX:
        Level=PWM_MAX

      os.system("gpio -g pwm " + str(pwm_gpio) + " " + str(Level))

      if avarage > LUX_DAY and night != False: # Day mode
        now = datetime.now(pytz.utc)
        if now >= sun['sunrise'] and now <= sun['sunset']:
          night = False
          GPIO.output(daynight_gpio, GPIO.LOW)
      elif avarage < LUX_NIGHT and night != True: # Night mode
        now = datetime.now(pytz.utc)
        if not (now >= sun['sunrise'] and now <= sun['sunset']):
          night = True
          GPIO.output(daynight_gpio, GPIO.HIGH)

      # print("Lux = {} | ".format(avarage) + "Level = {} | ".format(Level) + "Night = {}".format(night))
      file.write("Lux = {} | ".format(avarage) + "Level = {} | ".format(Level) + "Night = {}".format(night))
      file.write("\n\r")
except KeyboardInterrupt:
  pass
GPIO.cleanup()
i2cBus.write_byte_data(TSL2561_ADDR, 0x80, 0x00)
