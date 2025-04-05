local component = require "component"
local event = require "event"
local machines = require"purified".require "core.base.machines"
local craftables = require"purified".require "core.craftables"
local screen = require"purified".require "core.screen"
local config = require"purified".require "config"

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

        if config.EnableIsolationMode and not craftables.isMissingPurifiedWater then
            require "component".redstone.setOutput(config.sideRedstoneSignalOutput, 0)
        end

        screen.display()

        -- Avoid wasting excessive server performance.
        if craftables.skipSleep then craftables.skipSleep = false
        else os.sleep(config.secondClockCycle) end
    end
end

main()