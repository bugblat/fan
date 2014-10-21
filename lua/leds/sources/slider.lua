--[[
*************************************************************
 * This script is developed by Scouser, it uses modules
 * created by other developers but I have made minor / subtle
 * changes to get the effects I required.
 * Feel free to distribute and modify code,
 * but keep reference to its creator
**************************************************************
]]--


slider = Core.class(Sprite)

--local imgBase = getImgBase()
--local barTexture  = Texture.new("./sliderbar.png")
--local pillTexture = Texture.new("./sliderpill.png")
local imgBase = "resources/images/"
local barTexture = Texture.new(imgBase.."sliderbar.png")
local pillTexture = Texture.new(imgBase.."sliderpill.png")

--local font = getFont()
local fontBase = "resources/fonts/"
--local font = Font.new(fontBase.."font24.txt", fontBase.."font24.png")

local sw = 0
local sh = 0
local pw = 0
local ph = 0

function slider:init(tx, ty, pos, title, col, keepfocus)

  self.area = Sprite:new()
  self.keepFocus = keepfocus

  self:setClickCallback(nil,self)
  self:setMoveCallback(nil, self)

  self.bar = Bitmap.new(barTexture)
  self.pill = Bitmap.new(pillTexture)

  self:setCol(col)

  pw = self.pill:getWidth()
  sw = self.bar:getWidth()
  sh = self.bar:getHeight()
  
  tx = (application:getLogicalHeight() - sw) / 2      -- centre the bar
  
  self.focus = false
  self.bx = tx
  self.by = ty
  self.minx = tx + (pw/2)
  self.maxx = self.minx + sw - pw
  self.bar:setPosition(tx, ty-(sh/2))
  self.area:addChild(self.bar)
  self.px = self.minx
  self.ty = ty

  if pos > 100 then pos = 100 end

  self.tx = self.px + ((pos * (sw-pw)) / 100)
  self.pill:setAnchorPoint(0.5, 0.5)
  self.pill:setPosition(self.tx, self.ty)

  if title then
    local text = TextField.new(font, title)
    local width = text:getWidth()
    text:setPosition(tx+(sw/2)-(width/2),ty+6)
    text:setTextColor(0xffffff);
    self.area:addChild(text)
  end

  self.area:addChild(self.pill)
  self:addChild(self.area)

  self.area:addEventListener(Event.MOUSE_UP, self.onMouseUp, self)
  self.area:addEventListener(Event.MOUSE_MOVE, self.onMouseMove, self)
  self.area:addEventListener(Event.MOUSE_DOWN, self.onMouseDown, self)

  self:addEventListener(Event.ENTER_FRAME, self.frameStart, self)

end

function slider:onExitEnd()
  self.area:removeEventListener(Event.MOUSE_UP, self.onMouseUp)
  self.area:removeEventListener(Event.MOUSE_MOVE, self.onMouseMove)
  self.area:removeEventListener(Event.MOUSE_DOWN, self.onMouseDown)
  self:removeEventListener(Event.ENTER_FRAME, self.frameStart)
  collectgarbage()
end


function slider:setClickCallback(cb) self.clickCallback = cb end
function slider:setMoveCallback(cb) self.moveCallback = cb end

function slider:onMouseDown(event)
  if self:hitTestPoint(event.x, event.y) then
    self.focus = true
    event:stopPropagation()
  end
end

function slider:onMouseMove(event)
  if self.focus then
    if not self.keepFocus then
      if not self:hitTestPoint(event.x, event.y) then self.focus = false end
    end
    if self.focus then
      if event.x < self.minx then self.tx = self.minx
      elseif event.x > self.maxx then self.tx = self.maxx
      else self.tx = event.x
      end
      if self.moveCallback then self.moveCallback(self) end
      event:stopPropagation()
    end
  end
end

function slider:onMouseUp(event)
  if self.focus then
    if event.x < self.minx then self.tx = self.minx
    elseif event.x > self.maxx then self.tx = self.maxx
    else self.tx = event.x
    end
    self.focus = false
    event:stopPropagation()
    if self.clickCallback then self.clickCallback(self)
    else self:dispatchEvent(Event.new("click"))
    end
  end
end

function slider:getPos()
  local temp = ((self.tx-self.minx) * 100) / sw
  if temp < 0 then temp = 0
  elseif temp > 100 then temp = 100
  end
  return temp
end

function slider:setCol(col)
  self.area:setColorTransform(col.r, col.g, col.b, col.a)
end

function slider:frameStart(event)
  self.pill:setPosition(self.tx, self.ty)
end

