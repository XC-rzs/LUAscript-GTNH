local config = require "purified".require "config"

local presetData = {}

local nameToMachine = {}
nameToMachine["multimachine.purificationplant"] = "core"
nameToMachine["multimachine.purificationunitclarifier"] = "t1"
nameToMachine["multimachine.purificationunitozonation"] = "t2"
nameToMachine["multimachine.purificationunitflocculator"] = "t3"
nameToMachine["multimachine.purificationunitphadjustment"] = "t4"
nameToMachine["multimachine.purificationunitplasmaheater"] = "t5"
nameToMachine["multimachine.purificationunituvtreatment"] = "t6"
nameToMachine["multimachine.purificationunitdegasifier"] = "t7"
nameToMachine["multimachine.purificationunitextractor"] = "t8"

-- filter for search items in me network(label to name)
local materials = {}
materials["水"] = { name = "water" }
materials["过滤水"] = { name = "grade1purifiedwater" }
materials["臭氧水"] = { name = "grade2purifiedwater" }
materials["絮凝水"] = { name = "grade3purifiedwater" }
materials["pH中和水"] = { name = "grade4purifiedwater" }
materials["极端温度处理水"] = { name = "grade5purifiedwater" }
materials["紫外线处理电平衡水"] = { name = "grade6purifiedwater" }
materials["脱气无污染水"] = { name = "grade7purifiedwater" }
materials["8级净化水单元"] = { name = "grade8purifiedwater" }
materials["活性炭过滤器"] = { name = "gregtech:gt.metaitem.03", damage = 32233 }
materials["臭氧"] = { name = "ozone" }
materials["聚氯化铝"] = { name = "polyaluminiumchloride" }
materials["氢氧化钠粉"] = { name = "gregtech:gt.metaitem.01", damage = 2685 }
materials["氢氯酸"] = { name = "hydrochloricacid_gt5u" }
materials["氦等离子体"] = { name = "plasma.helium" }
materials["超级冷却液"] = { name = "supercoolant" }
materials["氦"] = { name = "helium" }
materials["氖"] = { name = "neon" }
materials["氪"] = { name = "krypton" }
materials["氙"] = { name = "xenon" }
materials["熔融中子"] = { name = "molten.neutronium" }
materials["熔融UV超导粗胚"] = { name = "molten.longasssuperconductornameforuvwire" }
materials["熔融UHV超导粗胚"] = { name = "molten.longasssuperconductornameforuhvwire" }
materials["熔融UEV超导粗胚"] = { name = "molten.superconductoruevbase" }
materials["熔融UIV超导粗胚"] = { name = "molten.superconductoruivbase" }
materials["熔融UMV超导粗胚"] = { name = "molten.superconductorumvbase" }
materials["上夸克释放催化剂"] = { name = "gregtech:gt.metaitem.03", damage = 32235 }
materials["下夸克释放催化剂"] = { name = "gregtech:gt.metaitem.03", damage = 32236 }
materials["奇夸克释放催化剂"] = { name = "gregtech:gt.metaitem.03", damage = 32237 }
materials["粲夸克释放催化剂"] = { name = "gregtech:gt.metaitem.03", damage = 32238 }
materials["底夸克释放催化剂"] = { name = "gregtech:gt.metaitem.03", damage = 32239 }
materials["顶夸克释放催化剂"] = { name = "gregtech:gt.metaitem.03", damage = 32240 }
materials["熔融无尽"] = { name = "molten.infinity" }

-- generate mapping from name to label
local mapNameToLabel = {}
for label, filter in pairs(materials) do
    if filter.damage ~=nil then
        mapNameToLabel[filter.name] = mapNameToLabel[filter.name] or {}
        mapNameToLabel[filter.name][filter.damage] = label
    else
        mapNameToLabel[filter.name] = label
    end
end
local function nameToLabel(name, damage)
    if damage == nil then
        return mapNameToLabel[name]
    end
    return mapNameToLabel[name][damage]
end

-- for config
materials["uv"] = materials["熔融UV超导粗胚"]
materials["uhv"] = materials["熔融UHV超导粗胚"]
materials["uev"] = materials["熔融UEV超导粗胚"]
materials["uiv"] = materials["熔融UIV超导粗胚"]
materials["umv"] = materials["熔融UMV超导粗胚"]

-- preset recipe
local KL = 1000
local MARGIN = 1.2

local recipe = {}
recipe.t1 = {
    water = { filter = materials["水"], num = KL },
    others = {
        { filter = materials["活性炭过滤器"], num = 1 }
    },
    output = { filter = materials["过滤水"], num = 900 },
    power = 30720
}
recipe.t2 = {
    water = { filter = materials["过滤水"], num = KL },
    others = {
        { filter = materials["臭氧"], num = 1024*KL }
    },
    output = { filter = materials["臭氧水"], num = 900 },
    power = 30720
}
recipe.t3 = {
    water = { filter = materials["臭氧水"], num = KL },
    others = {
        { filter = materials["聚氯化铝"], num = 1000*KL }
    },
    output = { filter = materials["絮凝水"], num = 900 },
    power = 122880
}
recipe.t4 = {
    water = { filter = materials["絮凝水"], num = KL},
    others = {
        { filter = materials["氢氧化钠粉"], num = 245 * MARGIN },
        { fiiter = materials["氢氯酸"], num = 2450 * MARGIN }
    },
    output = { filter = materials["pH中和水"], num = 900 },
    power = 122880
}
recipe.t5 = {
    water = { filter = materials["pH中和水"], num = KL },
    others = {
        { filter = materials["氦等离子体"], num = 300 * MARGIN },
        { filter = materials["超级冷却液"], num = 6000 * MARGIN}
    },
    output = { filter = materials["极端温度处理水"], num = 900 },
    power = 491520
}
recipe.t6 = {
    water = { filter = materials["极端温度处理水"], num = KL },
    others = {},
    output = { filter = materials["紫外线处理电平衡水"], num = 900 },
    power = 491520
}
recipe.t7 = {
    water = { filter = materials["紫外线处理电平衡水"], num = KL },
    others = {
        { filter = materials["氦"], num = 10000 },
        { filter = materials["氖"], num = 7500 },
        { filter = materials["氪"], num = 5000 },
        { filter = materials["氙"], num = 2500 },
        { filter = materials["超级冷却液"], num = 10000 },
        { filter = materials["熔融中子"], num = 4608 },
        { filter = materials[config.t7.superconductorTier], num = 1440 }
    },
    output = { filter = materials["脱气无污染水"], num = 900 },
    power = 1966080
}
recipe.t8 = {
    water = { filter = materials["脱气无污染水"], num = KL },
    others = {
        { filter = materials["上夸克释放催化剂"], num = 4 },
        { filter = materials["下夸克释放催化剂"], num = 4 },
        { filter = materials["奇夸克释放催化剂"], num = 4 },
        { filter = materials["粲夸克释放催化剂"], num = 4 },
        { filter = materials["顶夸克释放催化剂"], num = 4 },
        { filter = materials["底夸克释放催化剂"], num = 4 },
        { filter = materials["熔融无尽"], num = 2592 }
    },
    output = { filter = materials["8级净化水单元"], num = 900 },
    power = 7864320
}

local errorList = {}
errorList[1] = "机器超时运行"
errorList[2] = "机器可能因缺少能量关机 或 无法识别到配方启动"
errorList[3] = "机器代理丢失，请检查适配器与水厂机器主方块是否保持连接状态"
errorList[4] = "未找到水厂主机主方块，请用适配器连接水厂主机主方块"

local voltage = {}
voltage["ev"] = 2048
voltage["iv"] = 8192
voltage["luv"] = 32768
voltage["zpm"] = 131072

presetData.nameToMachine = nameToMachine
presetData.nameToLabel = nameToLabel
presetData.materials = materials
presetData.recipe = recipe
presetData.errorList = errorList
presetData.voltage = voltage
presetData.tickClockCycle = 2400

return presetData