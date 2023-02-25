import std/[bitops, memfiles]

type
  Pin* = range[0 .. 53]

const
  gpioStart      = 0x20200000
  offsetGpfsel0  = 0x00000000
  offsetGpfsel1  = 0x00000004
  offsetGpfsel2  = 0x00000008
  offsetGpfsel3  = 0x0000000C
  offsetGpfsel4  = 0x00000010
  offsetGpfsel5  = 0x00000014
  offsetGpset0   = 0x0000001C
  offsetGpset1   = 0x00000020
  offsetGpclr0   = 0x00000028
  offsetGpclr1   = 0x0000002C
  offsetGplev0   = 0x00000034
  offsetGplev1   = 0x00000038
  offsetGpioEnd  = 0x000000A0

func ptrFromOffset(p: pointer, offset: int): ptr[uint32] =
  cast[ptr uint32](cast[ByteAddress](p) + offset)

let
  mm*: MemFile = open("/dev/mem", mode = fmReadWrite,
                      offset = gpioStart, mappedSize = offsetGpioEnd)
  gpfsel0* = ptrFromOffset(mm.mem, offsetGpfsel0)
  gpfsel1* = ptrFromOffset(mm.mem, offsetGpfsel1)
  gpfsel2* = ptrFromOffset(mm.mem, offsetGpfsel2)
  gpfsel3* = ptrFromOffset(mm.mem, offsetGpfsel3)
  gpfsel4* = ptrFromOffset(mm.mem, offsetGpfsel4)
  gpfsel5* = ptrFromOffset(mm.mem, offsetGpfsel5)
  gpset0*  = ptrFromOffset(mm.mem, offsetGpset0)
  gpset1*  = ptrFromOffset(mm.mem, offsetGpset1)
  gpclr0*  = ptrFromOffset(mm.mem, offsetGpclr0)
  gpclr1*  = ptrFromOffset(mm.mem, offsetGpclr1)
  gplev0*  = ptrFromOffset(mm.mem, offsetGplev0)
  gplev1*  = ptrFromOffset(mm.mem, offsetGplev1)

proc gpset*(pin: Pin) =
  let pinOffset = (1 shl (pin mod 32)).uint32
  if pin < 32:
    gpset0[] = pinOffset
  else:
    gpset1[] = pinOffset

proc gpclr*(pin: Pin) =
  let pinOffset = (1 shl (pin mod 32)).uint32
  if pin < 32:
    gpclr0[] = pinOffset
  else:
    gpclr1[] = pinOffset

proc gpfsel(pin: Pin): ptr[uint32] =
  case pin
  of 0..9:   gpfsel0
  of 10..19: gpfsel1
  of 20..29: gpfsel2
  of 30..39: gpfsel3
  of 40..49: gpfsel4
  of 50..53: gpfsel5

proc setInputPin*(gpfsel: ptr[uint32], pin: Pin) =
  let pinOffset = (0b111 shl ((pin mod 10) * 3)).uint32
  gpfsel[].clearMask(pinOffset)

proc setOutputPin*(gpfsel: ptr[uint32], pin: Pin) =
  let pinOffset = (0b001 shl ((pin mod 10) * 3)).uint32
  gpfsel[].setMask(pinOffset)

proc setInputPins*(pins: varargs[Pin]) =
  for pin in pins:
    setInputPin(pin.gpfsel, pin)

proc setOutputPins*(pins: varargs[Pin]) =
  for pin in pins:
    setOutputPin(pin.gpfsel, pin)
