local component = require "component"
local event = require "event"
local require = require"purified".require

local machines = require "core.base.machines"
local craftables = require "core.craftables"
local screen = require "core.screen"
local config = require "config"

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