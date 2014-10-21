--[[

This example demonstrates a generic Button class

This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
(C) 2010 - 2011 Gideros Mobile

]]--

application:setBackgroundColor(0xaaccee)

appWidth  = application:getLogicalWidth()

local font = TTFont.new("PTC55F.ttf", 18, true)

-- create a label to show number of clicks
local label = TextField.new(font, "Clicked 0 time(s)")
label:setPosition((appWidth - label:getWidth())/2, 240)
stage:addChild(label)

-- create the up and down sprites for the button
local up = Bitmap.new(Texture.new("button_up.png"))
local down = Bitmap.new(Texture.new("button_down.png"))

-- create the button
local button = Button.new(up, down)

-- register to "click" event
local click = 0
button:addEventListener("click",
  function()
    click = click + 1
    label:setText("Clicked " .. click .. " time(s)")
    label:setPosition((appWidth - label:getWidth())/2, 240)
  end)

button:setPosition(40, 150)
stage:addChild(button)
