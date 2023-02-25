import std/[bitops, os]
import gpio

type
  BusyState* = enum
    ready, busy
  OnOffState* = enum
    on, off
  ResetState* = enum
    normal, reset
  LcdStatus* = tuple
    busy: BusyState
    onoff: OnOffState
    reset: ResetState

               # pin mapping
const          # gpio  # lcd
  pinRS*:  Pin = 8     # 4
  pinRW*:  Pin = 9     # 5
  pinDB0*: Pin = 14    # 7
  pinDB1*: Pin = 15    # 8
  pinDB2*: Pin = 2     # 9
  pinDB3*: Pin = 3     # 10
  pinDB4*: Pin = 4     # 11
  pinDB5*: Pin = 5     # 12
  pinDB6*: Pin = 6     # 13
  pinDB7*: Pin = 7     # 14
  pinE*:   Pin = 10    # 6
  pinCS1*: Pin = 11    # 15
  pinCS2*: Pin = 12    # 16
  pinRST*: Pin = 13    # 17
  cmdPins* =  [pinDB0, pinDB1, pinDB2, pinDB3, pinDB4, pinDB5, pinDB6, pinDB7, pinRW, pinRS]
  dataPins* = [pinDB0, pinDB1, pinDB2, pinDB3, pinDB4, pinDB5, pinDB6, pinDB7]

proc lcdSetChip1*(on: bool) =
  setOutputPins(pinCS1)
  if on:
    gpset pinCS1
  else:
    gpclr pinCS1

proc lcdSetChip2*(on: bool) =
  setOutputPins(pinCS2)
  if on:
    gpset pinCS2
  else:
    gpclr pinCS2

proc lcdWrite* =
  setOutputPins(pinE)
  gpclr pinE

  gpset pinE
  sleep(1)
  gpclr pinE

proc lcdReset* =
  setOutputPins(pinRST)
  gpset pinRST
  gpclr pinRST
  sleep(1)
  gpset pinRST

proc lcdWriteInstruction*(cmd: range[0..1023]) =
  setOutputPins(cmdPins)
  for i in 0..<10:
    if (cmd and (1 shl i)) != 0:
      gpset cmdPins[i]
    else:
      gpclr cmdPins[i]
  lcdWrite()

proc lcdOn* =
  lcdWriteInstruction(0x3f)

proc lcdOff* =
  lcdWriteInstruction(0x3e)

proc lcdSetAddress*(address: range[0..63]) =
  lcdWriteInstruction(0x40 + address)

proc lcdSetPage*(page: range[0..7]) =
  lcdWriteInstruction(0xb8 + page)

proc lcdSetDisplayStartLine*(line: range[0..63]) =
  lcdWriteInstruction(0xc0 + line)

proc lcdReadStatus*: uint32 =
  setInputPins(dataPins)
  setOutputPins(pinE, pinRW, pinRS)
  gpclr pinE
  gpset pinRW
  gpclr pinRS

  gpset pinE
  sleep(1)
  result = gplev0[]
  gpclr pinE

proc lcdWriteData*(data: uint8) =
  lcdWriteInstruction(0x200 + data)

proc lcdReadData*: uint32 =
  setInputPins(dataPins)
  setOutputPins(pinE, pinRW, pinRS)
  gpclr pinE
  gpset pinRW
  gpset pinRS

  gpset pinE
  sleep(1)
  result = gplev0[]
  gpclr pinE

proc lcdStatus*: LcdStatus =
  let data = lcdReadStatus()
  result = (busy:  if data.testBit(pinDB7.int): busy  else: ready,
            onoff: if data.testBit(pinDB5.int): off   else: on,
            reset: if data.testBit(pinDB4.int): reset else: normal)

proc lcdData*: uint8 =
  let data = lcdReadData()
  for pin in dataPins:
    if data.testBit(pin.int):
      result.setBit(pin.int)

proc lcdClearChip =
  lcdSetPage(0)
  lcdSetAddress(0)
  for page in 0..7:
    lcdSetPage(page)
    for address in 0..63:
      lcdWriteData(0)
  lcdSetPage(0)
  lcdSetAddress(0)

proc lcdClear* =
  lcdSetChip1(true)
  lcdSetChip2(true)
  lcdClearChip()
