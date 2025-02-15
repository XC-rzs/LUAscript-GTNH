local component = require "component"
local event = require "event"
local gpu = component.gpu

local tui = {thisPage = false}

local function drawRectangle(width, height, color)
    local top = "╭"
    local middle = "│"
    local bottom = "╰"
    for i = 1, width - 2 do
        top = top .. "─"
        middle = middle .. " "
        bottom = bottom .. "─"
    end
    top = top .. "╮"
    middle = middle .. "│"
    bottom = bottom .. "╯"
    local borders = {top,bottom}
    for i = 1, height - 2 do table.insert(borders,2,middle) end
    return borders
end

function tui.insertText(cx, cy, text, color)
    gpu.setForeground(color)
    gpu.set(cx + #text/2, cy, text)
end

-- 页面类
tui.Page = {name = "page", bordersColor = 0xFFFFFF, pages = {}}
tui.Page.__index = tui.Page
function tui.Page:new(x, y, width, height, name, bordersColor)
    local object = {
        x = x,
        y = y,
        width = width,
        height = height,
        name = name,
        contents = {},
        bottoms = {},
        bordersColor = bordersColor
    }
    setmetatable(object, self)
    self.pages[object.name] = object
    return object
end

function tui.Page:addBottom(bottom)
    table.insert(self.bottoms, bottom)
end

function tui.Page:turnTo(name)
    event.ignore("touch", thisListen)
    return Page.pages[name]
end

function tui.Page:handleTouch(eventType, address, x, y, button, playerName)
    for _, bottom in pairs(self.bottoms) do
        if bottom:isInside(x, y) then
            bottom.action()
            return nil
        end
    end
end

function tui.Page:display(specDisplay)
    borsders = drawRectangle(self.width, self.height, self.bordersColor)
    for i = 1, #borsders do
        gpu.set(self.x, self.y + i - 1, borsders[i])
    end
    for height, content in pairs(self.contents) do
        gpu.set(self.x + 1, self.y + self.height + 1, content:sub(1, self.width - 1))
    end
    for _, bottom in pairs(self.bottoms) do
        bottom:draw()
    end
    local this = self
    tui.thisListen = function (eventType, address, x, y, button, playerName)
        this:handleTouch(eventType, address, x, y, button, playerName)
    end
    event.listen("touch", tui.thisListen)
    if specDisplay then
        specDisplay()
    end
end

-- 按钮类
tui.Bottom = {text = " ", bottomColor = 0x00FF00, textColor = 0xFFFFFF}
tui.Bottom.__index = tui.Bottom
function tui.Bottom:new(x, y, width, height, action, text, bottomColor, textColor)
    local object = {
        x = x,
        y = y,
        width = width,
        height = height,
        action = action,
        text = text,
        bottomColor = bottomColor,
        textColor = textColor,
        bePressed = false
    }
    setmetatable(object, self)
    return object
end

function tui.Bottom:isInside(x,y)
    return x >= self.x and
    x <= self.x + self.width and
    y <= self.y and
    y >= self.y + self.height
end

function tui.Bottom:draw()
    gpu.setBackground(self.bottomColor)
    gpu.fill(self.x, self.y, self.x + self.width, self.y + self.height, " ")
    tui.insertText(self.x + self.width/2, self.y + self.height/2, self.text:sub(1, self.width-2), self.textColor)
    gpu.setBackground(0x000000)
end

return tui