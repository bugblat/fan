--[[
This program demonstrates controlling LEDs on a BX8u board via
a lua script running on a PC or on an Android device.
It was developed by me (tim) by modifying Scouser's code for his
OptionsDemo program. Scouser's heading appears below this notice.

Be warned that it just about the first lua program I have written,
so it probably fails on many grounds of style.
]]--

--[[
*************************************************************
 This file is supplied as part of the OptionsDemo by Scouser

 * This script is developed by Scouser, it uses modules
 * created by other developers but I have made minor / subtle
 * changes to get the effects I required.
 * Feel free to distribute and modify code,
 * but keep reference to its creator
**************************************************************
]]--

--require("mobdebug").start() -- for ZeroBrane debugging
require "bxPlugin"

application:setBackgroundColor(0xaaccee)

stage:setOrientation(Stage.LANDSCAPE_LEFT)

local col = {r=243/255,g=206/255,b=0,a=1}

local redSlider
local greenSlider
local isOpen = false

function adjustRed(this)
  local pos = redSlider:getPos()
  col.r = 0.5 + (pos * 2.55)/(2 * 255)
  redSlider:setCol({r=col.r, g=0, b=0, a=1})
  if isOpen then
    local v = math.floor(63 *(pos/100))
    bx.ta(3)
    bx.td(v)
    bx.flush()
  end
end

function adjustGreen(this)
  local pos = greenSlider:getPos()
  col.g = 0.5 + (pos * 2.55)/(2 * 255)
  greenSlider:setCol({r=0, g=col.g, b=0, a=1})
  if isOpen then
    local v = math.floor(63 *(pos/100))
    bx.ta(4)
    bx.td(v)
    bx.flush()
  end
end

appHeight = application:getLogicalWidth()
appWidth  = application:getLogicalHeight()

local sX = 100
local sY = appHeight/3
redSlider = slider.new(sX,sY,(col.r*100),nil,{r=col.r,g=0,b=0,a=1})

-- Quick and dirty way of adding the callbacks to the sliders
redSlider:setMoveCallback(adjustRed)
redSlider:setClickCallback(adjustRed)

sY = (2*appHeight)/3
greenSlider = slider.new(sX,sY,(col.g*100),nil,{r=0,g=col.g,b=0,a=1})

greenSlider:setMoveCallback(adjustGreen)
greenSlider:setClickCallback(adjustGreen)

stage:addChild(redSlider)
stage:addChild(greenSlider)

local ver = bx.version()
local fontBase = "resources/fonts/"
local font = TTFont.new(fontBase .. "PTC55F.ttf", 24, true)

local y = 30
local label = TextField.new(font, "Fan library version: " .. ver)
label:setPosition((appWidth - label:getWidth())/2, y)
stage:addChild(label)

if bx.open() then
  isOpen = true
  local ok, d
  ok, d = bx.readReg(0, 32)
  if ok then
    d = "Register 0: " .. d
  else
    d = "Error reading register 0"
  end
  local reg0 = TextField.new(font, d)
  y = y + reg0:getHeight() + 10
  reg0:setPosition((appWidth - reg0:getWidth())/2, y)
  stage:addChild(reg0)

--[[ could also init from the value in the FPGA:
  ok, d = bx.readReg(3, 1)
  local v = string.byte(d)
  redSlider:setPos(100 * (v/63))
]]--

  bx.ta(2)
  bx.td(3)
  bx.flush()
end

-- EOF ----------------------------------------------------------------
