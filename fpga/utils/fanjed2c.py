#----------------------------------------------------------------------
# Name:        fanjed2c.py
# Purpose:     convert a Fan configuration from JEDEC to C
#
# Author:      Tim
#
# Created:     20/05/2014
# Copyright:   (c) Tim 2014
# Licence:     see the LICENSE.txt file
#----------------------------------------------------------------------
#!/usr/bin/env python

import sys, ctypes, os
from ctypes   import *
from os.path  import *

# import rpdb2
# rpdb2.start_embedded_debugger('pw')

outFile           = None
DEVICE_NAME_TAG   = 'NOTE DEVICE NAME:'
PACKAGE_TAG       = 'TQFP100'

CORRECT_DEVICE    = 'XO2-2000HC'

CFG_PAGE_SIZE     = 16
CFG_PAGE_DWORDS   = CFG_PAGE_SIZE/4
UFM_PAGE_SIZE     = 16

##---------------------------------------------------------
def processLine(aLine):
  global outFile
  line = aLine.strip('\n')
  v    = []
  for i in range(0, CFG_PAGE_DWORDS):
    a = line[(i*32):(i*32+32)]
    s = a[::-1]
    x = int(s, 2)
    v.append(x)
    if outFile:
      if x == 0:
        outFile.write('          0,')
      else:
        outFile.write(' 0x%08x,' % x)
  if outFile:
    outFile.write('\n')
  return v

##---------------------------------------------------------
def readJedecFile(jedecFileName, outName, dev):
  global outFile
  print('JEDEC file : ' + jedecFileName)
  print('Output file: ' + outName)

  outFile = open(outName, 'wt')
  outFile.write("\n// JEDEC data from %s"
    "\n// reversed for JTAG programming, 128 bits (one frame) per line"
    "\n\n" % jedecFileName);

  data = []
  correctDevice = False
  jedecID = None

  try :
    jedecFile = open(jedecFileName, 'r')
  except IOError :
    print 'JEDEC file not found - exiting'
    return


  print('starting to read JEDEC file ') ,
  lnum = 0;
  state = 'initial'

  for line in jedecFile:
    lnum += 1
    if (lnum % 250) == 0:
      print('.') ,

    if len(line) < 1:
      continue

    # check JEDEC for, e.g., NOTE DEVICE NAME:  LCMXO2-2000HC-4TQFP100*
    if DEVICE_NAME_TAG in line:
      jedecID = line.strip()
      correctDevice = (dev in line) and (PACKAGE_TAG in line)
      if not correctDevice:
        break

    c0 = line[0]
    valid = (c0=='0') or (c0=='1')
    if state == 'initial':
      if valid:
        print('\nfirst configuration data line: %d' % lnum)
        outFile.write('\n// first configuration data line is: \n// %s\n' % line)
        state = 'inData'
        v = processLine(line)
        data.append(v)
      else:
        outFile.write('// %s' % line)
    elif state == 'inData':
      if valid:
        v = processLine(line)
        data.append(v)
      else:
        print('\nlast configuration data line: %d' % (lnum-1))
        state = 'finished'
        break

  jedecFile.close()
  if outFile:
    outFile.write('\n// %d frames\n' % len(data))
    outFile.close()

  if not correctDevice:
    print('\nJEDEC file does not match FPGA')
    print('\n  FPGA should be ' + dev)
    if jedecID:
      print('\n  JEDEC identifies as "' + jedecID + '"')
    return []

  print('%d frames' % len(data))
  print('finished reading JEDEC file')
##return data

##---------------------------------------------------------
def main():
  print('====================hello==========================')
  jedecFileName = None
  try:
    try:
      jedecFileName = sys.argv[1]
    except:
      print 'Usage: fanjed2c.py <JEDEC_File>'
      os._exit(2)

    if jedecFileName:
      try:
        outName = sys.argv[2]
      except:
        outName = splitext(basename(jedecFileName))[0] + ".txt"
      readJedecFile(jedecFileName, outName, CORRECT_DEVICE)

  except:
    e = sys.exc_info()[0]
    print('\nException caught %s\n' % e)

  print('\n==================== bye ==========================')

##---------------------------------------------------------
if __name__ == '__main__':
  main()

# EOF -----------------------------------------------------------------
