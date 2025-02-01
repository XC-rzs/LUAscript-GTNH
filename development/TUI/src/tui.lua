local component = require "component"
local gpu = component.gpu

tui = {}

local function drawRectangle(x, y, length, height, color)
    local top = "╭"
    local middle = "│"
    local bottom = "╰"
    for i = 1, lenth - 2 do
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

local function insertText(x, y, length, height, color)
     
end

function tui.setbottom(x, y, length, height, text, bordersColor, textColor)

end

return tui