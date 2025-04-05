local sides = require "sides"

local KL = 1000
local ML = 1000*KL
local GL = 1000*ML

return {
    inputEnergy = {
        energy = nil,
        voltage = nil,
        ampere = nil,
    },
    t1 = {
        minBufferStock = 1*KL,
        parallel = 1,
    },
    t2 = {
        minBufferStock = 1*KL,
        parallel = 1,
    },
    t3 = {
        minBufferStock = 1*KL,
        parallel = 1,
    },
    t4 = {
        minBufferStock = 1*KL,
        parallel = 1,
    },
    t5 = {
        minBufferStock = 1*KL,
        parallel = 1,
    },
    t6 = {
        minBufferStock = 1*KL,
        parallel = 1,
    },
    t7 = {
        minBufferStock = 1*KL,
        parallel = 1,
        -- 选填 "uv" / "uhv" / "uev" / "uiv" / "umv"
        -- 默认为 "uv"
        superconductorTier = "uv"
    },
    t8 = {
        minBufferStock = 0,
        parallel = 1,
    },
    EnableMaterialsAmountCheck = true,
    EnableGrade1Material_Water_Check = false,
    EnableIsolationMode = false,
    sideRedstoneSignalOutput = sides.top,
    secondClockCycle = 1
}