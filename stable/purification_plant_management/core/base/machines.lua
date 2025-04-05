local component = require "component"
local presetData = require "purified".require "core.base.preset_data"
local bigInt = require "purified".require "lib.bigint"

local machines = {}
machines.machines = {}
machines.machines.energyHatch = { proxy = false, name = "energyHatch" }
machines.machines.core = { proxy = false, name = "core" }
machines.machines.t1 = { proxy = false, recipe = presetData.recipe["t1"], name = "t1" }
machines.machines.t2 = { proxy = false, recipe = presetData.recipe["t2"], name = "t2" }
machines.machines.t3 = { proxy = false, recipe = presetData.recipe["t3"], name = "t3" }
machines.machines.t4 = { proxy = false, recipe = presetData.recipe["t4"], name = "t4" }
machines.machines.t5 = { proxy = false, recipe = presetData.recipe["t5"], name = "t5" }
machines.machines.t6 = { proxy = false, recipe = presetData.recipe["t6"], name = "t6" }
machines.machines.t7 = { proxy = false, recipe = presetData.recipe["t7"], name = "t7" }
machines.machines.t8 = { proxy = false, recipe = presetData.recipe["t8"], name = "t8" }

-- "hatch.energy"|"hatch.wireless.receiver"|"_lplaser_hatch_"
local function isEnergyHatch(machineName)
    local result = false

    if machineName:match("hatch.energy") then
        result = true
    elseif machineName:match("hatch.wireless.receiver") then
        result = true
    elseif machineName:match("_lplaser_hatch_") then
        result = true
    end

    return result
end

---@return boolean : if energy change then return true else false
function machines.getProxy()
    local energyChange = false

    local proxy
    local name
    for address in pairs(component.list("gt_machine")) do
        proxy = component.proxy(address)

        name = proxy.getName()
        if isEnergyHatch(name) then
            machines.machines.energyHatch.proxy = proxy
            energyChange = true
        end

        name = presetData.nameToMachine[name]
        if name ~= nil and machines.machines[name].proxy ~= nil then
            machines.machines[name].proxy = proxy
        end
    end

    return energyChange
end

--[[
        (wireless) energy hatch
            =ampere -- match("multi(%d+)") : number
            =voltage -- match("tier.(%d+)") : getVoltage(number)
                =if ampere == nil then match("tunnel(%d+)") : getAmpere(number)
                    =voltage -- As above
                        =if ampere == nil then ampere = 1
                            =voltage -- As above
                    
        laser hatch
            =ampere -- match("tunnel(%d+)") : getAmpere(number)
            =voltage -- match("tier.(%d+)") : getVoltage(number)
                =if ampere == nil then match("hatch_(%d+)") : number
                    =voltage -- match("[^_]+") : string : "ev"|"iv"|"luv"|"zpm"
--]]

local function getAmpere(level)
    local startA = bigInt.new(64)
    local rate = bigInt.exponentiate(bigInt.new(4), bigInt.new(level))
    
    return startA * rate
end

local function getVoltage(tier)
    local startV = bigInt.new(8)
    local rate = bigInt.exponentiate(bigInt.new(4), bigInt.new(tier))

    return startV * rate
end

---@param machineName string : the name of machine
---@return table : energy
---@return table : voltage
---@return table : ampere
function machines.getEnergy()
    local machineName = machines.machines.energyHatch.proxy.getName()

    local energy
    local ampere
    local voltage

    -- laser hatch
    ampere = machineName:match("tunnel(%d+)")
    if type(ampere) == "string" then
        ampere = getAmpere(ampere)
        voltage = getVoltage(machineName:match("tier.(%d+)"))
    elseif type(machineName:match("multi(%d+)")) == "string" then
        ampere = getAmpere(machineName:match("multi(%d+)"))
        voltage = getVoltage(machineName:match("tier.(%d+)"))
    elseif type(machineName:match("hatch_(%d+)")) == "string" then
        ampere = bigInt.new(machineName:match("hatch_(%d+)"))
        voltage = bigInt.new(presetData.voltage(machineName:match("[^_]+")))
    else
        ampere = bigInt.new(1)
        voltage = getVoltage(machineName:match("tier.(%d+)"))
    end

    energy = bigInt.unserialize(ampere * voltage, "string")
    ampere = bigInt.unserialize(ampere, "string")
    voltage = bigInt.unserialize(voltage, "string")
    return energy, voltage, ampere
end

function machines.getCurrentParallel(machine)
    local information = machine.proxy.getSensorInformation()
    for _, info in ipairs(information) do
        if info:match("Current parallel: §e") == "Current parallel: §e" then
            return info:match("Current parallel: §e(%d+)")
        end
    end
end

return machines