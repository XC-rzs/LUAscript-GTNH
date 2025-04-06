if not next(require "component".list("internet")) then error("请插入因特网卡") end
local fs = require "filesystem"
local shell = require "shell"

local workDir = fs.path(debug.getinfo(2, "S").source:match("=(.+)")) .. "purification_plant_management"
local rootUrl = "https://gitee.com/CrzS/LUAscript-GTNH/raw/new_script/stable/purification_plant_management"
local downloadList = {
    {"/start.lua", 51104},
    {"/purified_package.lua", 49097},
    {"/config.lua", 55615},
    {"/lib/bigint.lua", 58814},
    {"/core/screen.lua", 35319},
    {"/core/craftables.lua", 43072},
    {"/core/core_logic.lua", 62085},
    {"/core/base/machines.lua", 9835},
    {"/core/base/me_network.lua", 57867},
    {"/core/base/preset_data.lua", 5345},
}

local crc16_table = {}
local poly = 0x1021
for byte = 0, 255 do
    local crc = byte << 8
    for _ = 1, 8 do
        if (crc & 0x8000) ~= 0 then
            crc = (crc << 1) ~ poly
        else
            crc = crc << 1
        end
        crc = crc & 0xFFFF
    end
    crc16_table[byte] = crc
end

local function crc16_file(filepath)
    local file = io.open(filepath, "rb")
    if not file then return nil end

    local crc = 0xFFFF
    while true do
        local chunk = file:read(4096)
        if not chunk then break end
        for i = 1, #chunk do
            local byte = chunk:byte(i)
            crc = (crc << 8) ~ crc16_table[(crc >> 8) ~ byte]
            crc = crc & 0xFFFF
        end
    end

    file:close()
    return crc
end

fs.makeDirectory(workDir)
local url, path, crc
for _, array in ipairs(downloadList) do
    url, path, crc = rootUrl .. array[1], workDir .. array[1], array[2]

    if not fs.exists(path) then
        fs.makeDirectory(fs.path(path))
    end

    for i = 1, 3 do
        shell.execute("wget -f " .. url .. " -O " .. path)
        if fs.exists(path) and crc == crc16_file(path) then
            break
        end
        if i == 3 then
            error("文件校验失败，达到最大重试次数")
        end
    end
end
