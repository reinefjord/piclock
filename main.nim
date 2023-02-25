import abstractlcd
import piclock

var frame: LcdFrame

var lcd = init()
while true:
  frame = drawTime()
  lcd = lcd.send(frame)
