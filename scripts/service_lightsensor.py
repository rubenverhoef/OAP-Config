#!/usr/bin/python3 -u

import smbus
import os
import RPi.GPIO as GPIO
import subprocess
from time import sleep

# ---------------------------------
# the addresss of TSL2561 can be
# 0x29, 0x39 or 0x49
BUS = 1
TSL2561_ADDR = 0x39
daynight_gpio = 1
pwm_gpio = 12
TSL2561_CHECK_INTERVAL=1
PWM_MAX=1023
LUX_DARK_BR=50
LUX_FULL_BR=200
LUX_DAY=100
LUX_NIGHT=50
# ---------------------------------

i2cBus = smbus.SMBus(BUS)

lastvalue = 0

GPIO.setmode(GPIO.BCM)
GPIO.setup(daynight_gpio, GPIO.OUT)
GPIO.output(daynight_gpio, GPIO.LOW)
os.system("gpio -g mode " + str(pwm_gpio) + " pwm")
a=-(PWM_MAX/(LUX_FULL_BR-LUX_DARK_BR))
b=(PWM_MAX+((PWM_MAX/(LUX_FULL_BR-LUX_DARK_BR)))*LUX_DARK_BR)

Lux_Array = [100, 100, 100, 100, 100]

try:
  while True:
    sleep (TSL2561_CHECK_INTERVAL)

    if i2cBus.read_byte_data(TSL2561_ADDR, 0x80, 0x03) != 0x03:
      # Startup TSL2561
      i2cBus.write_byte_data(TSL2561_ADDR, 0x80, 0x03)
    
    else:
      # read global brightness
      # read low byte
      LSB = i2cBus.read_byte_data(TSL2561_ADDR, 0x8C)
      # read high byte
      MSB = i2cBus.read_byte_data(TSL2561_ADDR, 0x8D)
      Ambient = (MSB << 8) + LSB
      #print ("Ambient: {}".format(Ambient))

      # read infra red
      # read low byte
      LSB = i2cBus.read_byte_data(TSL2561_ADDR, 0x8E)
      # read high byte
      MSB = i2cBus.read_byte_data(TSL2561_ADDR, 0x8F)
      Infrared = (MSB << 8) + LSB
      #print ("Infrared: {}".format(Infrared))

      # Calc visible spectrum
      Visible = Ambient - Infrared
      #print ("Visible: {}".format(Visible))

      # Calc factor Infrared/Ambient
      Ratio = 0
      Lux = 0
      if Ambient != 0:
        Ratio = float(Infrared)/float(Ambient)
        #print ("Ratio: {}".format(Ratio))

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
        Luxrounded=round(Lux,0)

        # os.system("echo {} > /tmp/tsl2561".format(Luxrounded))
        Lux_Array.append(Luxrounded)
        Lux_Array.pop(0)
        total=0
        for x in Lux_Array:
          total=total+x
        avarage=total/5

        Level=int(round(a*avarage+b,0))
        if Level < 0:
          Level=0
        elif Level > PWM_MAX:
          Level=PWM_MAX

        if avarage > LUX_DAY:
          GPIO.output(daynight_gpio, GPIO.LOW)
        elif avarage < LUX_NIGHT:
          GPIO.output(daynight_gpio, GPIO.HIGH)

        os.system("gpio -g pwm " + str(pwm_gpio) + " " + str(Level))

        # print("Lux = {} | ".format(avarage) + "Level = {}".format(Level))
except KeyboardInterrupt:
  pass
GPIO.cleanup()
