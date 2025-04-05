local component = require "component"
local presetData = require "purified".require "core.base.preset_data"

local interface = component.me_interface

local meNetwork = {}

---@param filters table : an array composed of filters
---@return table : mapping from material label to its num
function meNetwork.getFilteredItems(filters)
    filters = filters or {}
    checkArg(1, filters, "table")

    -- Return early if the filter is empty
    if next(filters) == nil then
        return {}
    end

    local items
    local object = {}
    for _, filter in ipairs(filters) do
        items = interface.getItemsInNetwork(filter)

        if next(items) == nil then
            object[presetData.nameToLabel(filter.name, filter.dagamge)] = 0
        else
            object[presetData.nameToLabel(items[1].name, items[1].damage)] = items[1].size
        end
    end

    return object
end

---@param filters table : an array composed of filters
---@return table : mapping from material label to its num
function meNetwork.getFilteredFlquids(filters)
    filters = filters or {}
    checkArg(1, filters, "table")

    -- Return early if the filter is empty
    if next(filters) == nil then
        return {}
    end
    
    local raw = interface.getFluidsInNetwork()
    
    -- translate raw to mapping from flquids name to their amount  
    local map = {}
    for _, flquid in ipairs(raw) do
        map[flquid.name] = flquid.amount
    end


    local object = {}
    for _, filter in ipairs(filters) do
        if map[filter.name] == nil then
            object[presetData.nameToLabel(filter.name)] = 0
        else
            object[presetData.nameToLabel(filter.name)] = map[filter.name]
        end
    end

    return object
end

return meNetwork