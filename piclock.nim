import std/[random, times]
import pixie
import abstractlcd

let font = readFont("scientifica.ttf")
font.size = 11

proc drawSomethingRandom*: LcdFrame =
  for x in 0..127:
    for y in 0..63:
      result[x][y] = rand(1) == 1

proc drawText*(text: string): LcdFrame =
  let image = newImage(128, 64)
  image.fillText(font, text, translate(vec2(40, 25)))
  for y in 0..<image.height:
    for x in 0..<image.width:
      let rgbx = image.unsafe[x, y]
      result[x][y] = rgbx.a > 0

proc drawTime*(): LcdFrame =
  let dt = now()
  result = dt.format("HH:mm:ss").drawText()
