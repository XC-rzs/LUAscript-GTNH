local event = require "event"

local function findMachine()
    for address, name in pairs(component.list("gt_machine")) do
        local this = component.proxy(address)
        if Machine.machines[this.getName()] == false then
            this.setWorkAllowed(false)
            local object = Machine:new(name)
            object.api = this
        end
    end
    event.timer(10, findMachine, 1)
end

local function init()
   event.timer(0, findMachine, 1) 
end