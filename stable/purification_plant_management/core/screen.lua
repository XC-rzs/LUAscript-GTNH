local gpu = require"component".gpu
local presetData = require"purified".require "core.base.preset_data"
local config = require"purified".require "config"

gpu.freeAllBuffers()
local screen = {}
local defaultFontColor = 0xFFFFFF
local screenIndex = 0
local bufferIndex = gpu.allocateBuffer(160, 50)

local page1 = {}
local machinesStatus = {}
machinesStatus[1] = {
    str = "未找到",
    color = 0x666666
}
machinesStatus[2] = {
    str = "空闲中",
    color = 0xFFFFFF
}
machinesStatus[3] = {
    str = "工作中",
    color = 0x00FF00
}
page1.variableContent = {}
page1.variableContent[1] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t1.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[2] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t2.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[3] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t3.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[4] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t4.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[5] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t5.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[6] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t6.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[7] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t7.parallel, last = "未知", recommend = "未知" } }
page1.variableContent[8] = { status = machinesStatus[1], missingMaterials = {}, parallel = { config = config.t8.parallel, last = "未知", recommend = "未知" } }
page1.content = {"\ttier-1", "\ttier-2", "\ttier-3", "\ttier-4", "\ttier-5", "\ttier-6", "\ttier-7", "\ttier-8"}
page1.energy = { energy = "未知", ampere = "未知", voltage = "未知" }

local function drawOutline()
    local y = 11

    gpu.fill(5, 4, 150, 1, "=")
    gpu.fill(5, 6, 150, 1, "=")
    for i = 1, 8 do
        gpu.fill(5, y, 150, 1, "=")
        y = y + 5
    end
    gpu.fill(5, 4, 1, 43, "=")
    gpu.fill(155, 4, 1, 43, "=")
end

function page1:display()
    os.execute('cls')

    drawOutline()
    print("\n\n\n\n\t\t   状态\t\t缺乏原料：\n")
    local variableContent
    local missingMaterials
    local parallel
    local row = 9
    for i = 1, #self.content do
        gpu.setForeground(page1.variableContent[i].status.color)

        -- generate variable content
        variableContent = "\t  " .. page1.variableContent[i].status.str .. "\t    "
        missingMaterials = table.concat(self.variableContent[i].missingMaterials, "  ")
        if missingMaterials == "" and self.variableContent[i].status ~= "未找到" then
            missingMaterials = "无"
        end
        variableContent = variableContent .. missingMaterials

        parallel = table.concat({"设定并行: ", self.variableContent[i].parallel.config,
                                 "      实际并行(上次运行): ", self.variableContent[i].parallel.last,
                                 "      推荐并行: " .. self.variableContent[i].parallel.recommend})
        print(self.content[i] .. variableContent .. "\n\n\n\n")
        gpu.set(12, row, parallel)
        row = row + 5

        gpu.setForeground(defaultFontColor)
    end

    local energy = table.concat({"输入功率: " .. page1.energy.energy .. "(EU/t)",
                                 "输入电压:" .. page1.energy.voltage .. "(V)",
                                 "输入电流: " .. page1.energy.ampere .. "(A)"}, "      ")
    gpu.set(7, 47, energy)

    gpu.bitblt(screenIndex, 1, 1, 160, 50, bufferIndex, 1, 1)
end

local page2 = {}
page2.errorList = {}

function page2:display()
    os.execute('cls')
    print("\n\t发生错误！请检查，按下Enter键继续......\n\t\t错误信息：" .. self.errorList[1])
    for i = 2, #self.errorList do
        print("\t\t\t  " .. self.errorList[i])
    end
    self.errorList = {}
    gpu.bitblt(screenIndex, 1, 1, 160, 50, bufferIndex, 1, 1)
    io.read()
end

-- interface

---@param massage string : the massage of the error
function screen.addError(massage)
    checkArg(1, massage, "string")

    if massage == "no such component" then
        massage = presetData.errorList[3]
    elseif massage:match("^.*:.*: (.*)$") == "attempt to index a boolean value (field 'proxy')" then
        massage = presetData.errorList[4]
    end
    table.insert(page2.errorList, massage)
end

---@param grade number : the grade of machine
---@param nameList table : list of missing materials name
function screen.setMissingMaterials(grade, nameList)
    checkArg(1, grade, "number")
    checkArg(2, nameList, "table")

    page1.variableContent[grade].missingMaterials = nameList
end

---@param grade number : the grade of machine
---@param status number|string : 1 - "未找到"; 2 - "空闲中"; 3 - "工作中"
function screen.setMachineStatus(grade, status)
    checkArg(1, grade, "number")

    if type(status) == "string" then
        page1.variableContent[grade].status = status
    elseif type(status) == "number" then
        page1.variableContent[grade].status = machinesStatus[status]
    end
end

---@param grade string : the grade of machine
---@param type string : "last"|"recommend"
---@param parallel string : the size of parallel
function screen.setMachineParallel(grade, type, parallel)
    checkArg(1, grade, "string")
    checkArg(2, type, "string")
    checkArg(3, parallel, "string")

    page1.variableContent[grade + 0].parallel[type] = parallel
end

function screen.display()

    gpu.setActiveBuffer(bufferIndex)
    if next(page2.errorList) == nil then
        page1:display()
    else
        page2:display()
    end

    gpu.setActiveBuffer(screenIndex)
end

screen.energy = page1.energy

return screen
