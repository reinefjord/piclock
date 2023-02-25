import std/[bitops, enumerate]
import lcd

type
  LcdFrame* = array[0..127, array[0..63, bool]]
  ChipDiff = array[0..7, array[0..63, ref[uint8]]]
  FrameDiff = tuple
    cs1: ChipDiff
    cs2: ChipDiff
  ChipState = ref object
    address: int
    page: int
    on: bool
  LcdState = tuple
    cs1: ChipState
    cs2: ChipState
    frame: LcdFrame

func diff(frame, newFrame: LcdFrame): FrameDiff =
  proc set(cd: var ChipDiff; colMin, colMax: int) =
    for colIdx in colMin..colMax:
      let oldCol = frame[colIdx]
      let newCol = newFrame[colIdx]

      for pageIdx in 0..7:
        let colStartIdx = pageIdx * 8
        let colEndIdx = colStartIdx + 7
        let oldColData = oldCol[colStartIdx..colEndIdx]
        let newColData = newCol[colStartIdx..colEndIdx]

        if oldColData != newColData:
          var byte: uint8
          for i, b in enumerate(newColData):
            if b:
              byte.setBit(i)
          var dataRef: ref[uint8]
          new dataRef
          dataRef[] = byte
          cd[pageIdx][colIdx mod 64] = dataRef

  result.cs1.set(0, 63)
  result.cs2.set(64, 127)

proc send(cs: ChipState, cd: ChipDiff) =
  for pageIdx in 0..7:
    for colIdx in 0..63:
      if cd[pageIdx][colIdx] == nil:
        continue
      if cs.page != pageIdx:
        lcdSetPage(pageIdx)
      if cs.address != colIdx:
        lcdSetAddress(colIdx)
      lcdWriteData(cd[pageIdx][colIdx][])
      if cs.address == 63:
        if cs.page == 7:
          cs.page = 0
        else:
          cs.page += 1
        cs.address = 0
        lcdSetPage(cs.page)
        lcdSetAddress(cs.address)
      else:
        cs.address += 1

proc send*(state: LcdState, newFrame: LcdFrame): LcdState =
  let frameDiff = state.frame.diff(newFrame)

  # TODO: check this inside the loop to not do this if no data will be sent?
  if not state.cs1.on:
    lcdSetChip1(true)
    state.cs1.on = true

  if state.cs2.on:
    lcdSetChip2(false)
    state.cs2.on = false

  state.cs1.send(frameDiff.cs1)

  lcdSetChip1(false)
  state.cs1.on = false
  lcdSetChip2(true)
  state.cs2.on = true

  state.cs2.send(frameDiff.cs2)

  result = (cs1: state.cs1,
            cs2: state.cs2,
            frame: newFrame)

proc init*: LcdState =
  lcdSetChip1(true)
  lcdSetChip2(true)
  lcdReset()
  lcdOn()
  lcdClear()
  lcdSetDisplayStartLine(0)
  result.cs1 = ChipState(address: 0, page: 0, on: true)
  result.cs2 = ChipState(address: 0, page: 0, on: true)
