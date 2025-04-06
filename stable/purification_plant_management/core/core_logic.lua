local component = require "component"
local event = require "event"
local presetData = require "purified".require "core.base.preset_data"
local machines = require "purified".require "core.base.machines"
local craftables = require "purified".require "core.craftables"
local screen = require "purified".require "core.screen"
local config = require "purified".require "config"

-- check the type of inputEnergy
local typeV = type(config.inputEnergy.voltage)
local typeA = type(config.inputEnergy.ampere)
if typeV == "nil" or typeA == "nil" then
    config.inputEnergy.voltage = nil
    config.inputEnergy.ampere = nil
elseif typeV == "number" and typeA == "number" then
    config.inputEnergy.energy = config.inputEnergy.voltage * config.inputEnergy.ampere
else
    screen.addError(presetData.errorList[6])
    config.inputEnergy.voltage = nil
    config.inputEnergy.ampere = nil
end

local function init()
    if machines.getProxy() then
        local energy, voltage, ampere = machines.getEnergy()
        screen.energy.energy = config.inputEnergy.energy or energy
        screen.energy.voltage = config.inputEnergy.voltage or voltage
        screen.energy.ampere = config.inputEnergy.ampere or ampere
        craftables.setRecommendParallel()
    end
end

local function main()
    init()
    event.listen("component_added", function()
        init()
    end)

    local t = 0
    while true do
        local success, err = pcall(craftables.execute)
        if not success then
           screen.addError(err)
        end

        screen.display()

        -- Avoid wasting excessive server performance.
        if craftables.skipSleep then craftables.skipSleep = false
        else os.sleep(config.secondClockCycle) end
    end
end

main()