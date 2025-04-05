local require = require"purified".require

local presetData = require "core.base.preset_data"
local meNetwork = require "core.base.me_network"
local machines = require "core.base.machines"
local screen = require "core.screen"
local bigInt = require "lib.bigint"
local config = require "config"

local craftables = {}

craftables.skipSleep = false
craftables.hasCrafted = false
craftables.currentMaterialsLabelToNum = {}

---@param func function : the first param and the second param must be name and machine
---@return table : depend on the return value of func
local function iterateThenJudge(func, ...)
    local array = {...}
    local object = array[1]

    for name, machine in pairs(machines.machines) do

        -- If the machine exists (the recipe can be processed) and the recipe exists (excluding the water purification plant)
        if machine.proxy and machine.recipe then
            object = func(name, machine, ...)
        end
    end

    return object
end

---@return table : mapping from the materials label to their num
local function getMaterialsNum()
    local filters = {}
    for name, machine in pairs(machines.machines) do

        -- If the machine exists (the recipe can be processed) and the recipe exists (excluding the water purification plant)
        if machine.proxy and machine.recipe then
            table.insert(filters, machine.recipe.water.filter)
            table.insert(filters, machine.recipe.output.filter)
            for _, input in ipairs(machine.recipe.others) do
                table.insert(filters, input.filter)
            end
        end
    end

    -- Categorize the filters
    local filterItems = {}
    local filterFlquids = {}
    for _, filter in ipairs(filters) do
        if filter.damage == nil then
            table.insert(filterFlquids, filter)
        else
            table.insert(filterItems, filter)
        end
    end

    local labelToNum = meNetwork.getFilteredItems(filterItems)
    for label, num in pairs(meNetwork.getFilteredFlquids(filterFlquids)) do
        labelToNum[label] = num
    end

    return labelToNum
end

---@param actualLabelToNum table : mapping of actual materials label and their num
---@param targetLabelToNum table : mapping of target materials label and their num
---@return table : array of under target materials label
local function getUnderTargetMaterials(actualLabelToNum, targetLabelToNum)
    local object = {}
    local actual
    for label, target in pairs(targetLabelToNum) do
        actual = actualLabelToNum[label] or 0
        if actual < target then
            table.insert(object, label)
        end
    end

    return object
end

local function getUnderTargetPurifiedWaterRecipe()
    local targetLabelToNum = {}

    for name, machine in pairs(machines.machines) do

        -- If the machine exists (the recipe can be processed) and the recipe exists (excluding the water purification plant)
        if machine.proxy and machine.recipe then
            targetLabelToNum[presetData.nameToLabel(machine.recipe.output.filter.name)] = config[name].minBufferStock
        end
    end

    local array = getUnderTargetMaterials(craftables.currentMaterialsLabelToNum, targetLabelToNum)

    -- translate water name to recipe name
    local name
    local recipeNameList = {}
    for _, label in ipairs(array) do
        name = presetData.materials[label].name
        table.insert(recipeNameList, "t" .. name:match("grade(.)"))
    end
    table.sort(recipeNameList)

    return recipeNameList
end

local function areOtherMaterialsEnough(machine)
    local result = true

    local recipe = machine.recipe
    local targetLabelToNum = {}
    for _, input in ipairs(recipe.others) do
        targetLabelToNum[presetData.nameToLabel(input.filter.name, input.filter.damage)] = input.num
    end

    local arrar = getUnderTargetMaterials(craftables.currentMaterialsLabelToNum, targetLabelToNum)
    if next(arrar) ~= nil then
        result = false
    end

    return result
end

local function isMaterialsEnough(machine, recipeNameList)
    local result = true
    local recipe = machine.recipe
    local label = presetData.nameToLabel(recipe.water.filter.name)
    local targetLabelToNum = {
        [label] = recipe.water.num * config[machine.name].parallel
    }

    if not config.EnableGrade1Material_Water_Check and recipe.water.filter.name == "water" then
        targetLabelToNum = {
            ["水"] = -1
        }
    end

    local arrar = getUnderTargetMaterials(craftables.currentMaterialsLabelToNum, targetLabelToNum)
    if next(arrar) ~= nil then

        -- add the missing purified water to the list
        table.insert(recipeNameList, "t" .. presetData.materials[label].name:match("grade(.)"))
        result = false
    end

    if result and config.EnableMaterialsAmountCheck and not areOtherMaterialsEnough(machine) then
        result = false
    end

    return result
end

local function waitForCycleToEnd(machine, second)
    local parallel = machines.getCurrentParallel(machine)
    screen.setMachineParallel(machine.name:match("t(.)"), "last", parallel)

    os.sleep(second)

    -- prevent infinite sleep
    for i = 1, 10 do
        if 0 == machine.proxy.getWorkProgress() then
            return
        end
        os.sleep(1)
    end

    -- machine processing timeout
    screen.addError("(current work progress = " .. machine.getWorkProgress() .. ") " .. machine.name .. presetData.errorList[1])
end

local function startWork(machine)
    craftables.hasCrafted = true

    local proxy = machine.proxy
    local coreProxy = machines.machines.core.proxy
    proxy.setWorkAllowed(true)
    coreProxy.setWorkAllowed(true)

    local restTime
    for i = 1, 3 do
        restTime = presetData.tickClockCycle - proxy.getWorkProgress()
        if restTime > 0 and restTime < presetData.tickClockCycle then

            -- shut down the machine in advance to prevent it from continuing the next cycle when the program sleep
            proxy.setWorkAllowed(false)
            coreProxy.setWorkAllowed(false)
            waitForCycleToEnd(machine, (restTime // 20) - 5)
            return
        end

        os.sleep(2)
    end

    proxy.setWorkAllowed(false)
    coreProxy.setWorkAllowed(false)
    -- The machine may shut down due to lack of energy
    screen.addError(machine.name .. presetData.errorList[2])
end

local function tryToExecuteTheRecipe(machine, recipeNameList)

    -- wait for the cycle to the end
    local coreProxy = machines.machines.core.proxy
    local workProgress = coreProxy.getWorkProgress()
    while workProgress > 0 and workProgress < presetData.tickClockCycle do
        coreProxy.setWorkAllowed(false)
        print("\n\t\t\t(cache workprogress = " .. workProgress .. ")等待正在进行的循环结束......")
        os.sleep((presetData.tickClockCycle - coreProxy.getWorkProgress() + 20) / 20)
        workProgress = coreProxy.getWorkProgress()
    end


    if isMaterialsEnough(machine, recipeNameList) then
        screen.setMachineStatus(machine.name:match("t(.)") + 0, 3)
        screen.display()
        startWork(machine)
    end
    screen.setMachineStatus(machine.name:match("t(.)") + 0, 2)
end

-- interface

function craftables.execute()
    craftables.currentMaterialsLabelToNum = getMaterialsNum()
    craftables.updateToScreen()

    -- The machines name and recipes name are the same
    local recipeNameList = getUnderTargetPurifiedWaterRecipe()
    local currentMachine
    for i = 1, #recipeNameList do
        currentMachine = machines.machines[table.remove(recipeNameList)]
        tryToExecuteTheRecipe(currentMachine, recipeNameList)

        -- each execution processes only one unit of purified water
        if craftables.hasCrafted then
            craftables.skipSleep = true
            craftables.hasCrafted = false
            break
        end
    end
end

function craftables.setRecommendParallel()
    local energy = screen.energy.energy
    
    local recommend
    local grade
    for name, machine in pairs(machines.machines) do
        
        if machine.recipe and machine.name ~= "energyHatch" then
            grade = name:match("t(.)")
            recommend = bigInt.unserialize(bigInt.new(energy) / bigInt.new(machine.recipe.power), "string")
            screen.setMachineParallel(grade, "recommend", recommend)
        end
    end
end

function craftables.updateToScreen()
    local target = {}

    for name, machine in pairs(machines.machines) do

        -- If the machine exists (the recipe can be processed) and the recipe exists (excluding the water purification plant)
        if machine.proxy and machine.recipe then
            screen.setMachineStatus(name:match("t(.)") + 0, 2)

            for _, input in ipairs(machine.recipe.others) do
                target[machine.name] = target[machine.name] or {}
                target[machine.name][presetData.nameToLabel(input.filter.name, input.filter.damage)] = input.num
            end
        end
    end

    if config.EnableGrade1Material_Water_Check then
        target.t1["水"] = config.t1.parallel * 1000
    end

    local missingMaterials
    for name in pairs(target) do
        missingMaterials = getUnderTargetMaterials(craftables.currentMaterialsLabelToNum, target[name])
        screen.setMissingMaterials(name:match("t(.)") + 0, missingMaterials)
    end
end

return craftables
