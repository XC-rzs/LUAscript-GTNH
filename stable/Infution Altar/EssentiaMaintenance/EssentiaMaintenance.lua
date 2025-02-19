local component = require "component"

local config = {
	minEssentialStorage = 2048,
	Num_perRequest = 2048,
	maxRequestNum = 2,
	TagName = nil,
	IndividualEssentialStorage = {
		...
	},
	modemPort = 12306,
	redstoneOutputSide = require "sides".top
}

while next(component.list("me_controller")) == nil do
	print("未检测到me控制器，请检查") os.sleep(3) os.execute("cls")
end
local controller = component.me_controller

local craftables
local function getCraftables()
	craftables = {}
	local filter = {name = "thaumicenergistics:crafting.aspect"}
	for _, v in pairs(controller.getCraftables(filter)) do
		craftables[v.getItemStack().aspect] = v.request
	end
end

local function init()
	getCraftables()
	os.execute("cls")
end

local requestStack = {}
local requestStackMap = {}
local craftingEssential = {}
local errorRequestStack = {}

local function checkCraftCompletion()
	for i = #craftingEssential, 1, -1 do
		if craftingEssential[i].isDone() or craftingEssential[i].isCanceled() then
			requestStackMap[craftingEssential[i].name] = nil
			table.remove(craftingEssential, i)
		end
	end
end

local function request(name, num)
	checkCraftCompletion()
	if not requestStackMap[name] then
		table.insert(requestStack, { name = name, num = num })
		requestStackMap[name] = true
	end
	if #requestStack == 0 then
		requestStack = { table.unpack(errorRequestStack) }
		errorRequestStack = {}
	end
end

local function checkEssentialExist(Essential)
	local list = {}
    for _, v in pairs(Essential) do
    	list[v.label:match("^%S+"):lower()] = true
    end
    for name in pairs(craftables) do
    	if not list[name] then
    		local num = config.IndividualEssentialStorage[name]
    			and config.IndividualEssentialStorage[name].Num_perRequest
			request(name, num or config.Num_perRequest)
    	end
    end
end

local function checkEssentialEnough()
	local currentAllEssential = controller.getEssentiaInNetwork()
	checkEssentialExist(currentAllEssential)
	for _, v in pairs(currentAllEssential) do
		local name = v.label:match("^%S+"):lower()
		local minStorage = config.IndividualEssentialStorage[name] 
			and config.IndividualEssentialStorage[name].minStorage 
			or config.minEssentialStorage
		local num = config.IndividualEssentialStorage[name]
			and config.IndividualEssentialStorage[name].Num_perRequest
		if v.amount < minStorage then
			request(name, num or config.Num_perRequest)
		end
	end
end

local function signalHandle(boolean)
	if next(component.list("modem")) then
		component.modem.setStrength(400)
		component.modem.broadcast(config.modemPort, boolean)
	end
	if next(component.list("redstone")) then
		if boolean then
			component.redstone.setOutput(config.redstoneOutputSide, 15)
		else
			component.redstone.setOutput(config.redstoneOutputSide, 0)
		end
	end
end

local isEssentialEnough = false
local function sendSignal()
	if next(requestStackMap) == nil and isEssentialEnough == false then
		isEssentialEnough = true
		signalHandle(isEssentialEnough)
	elseif isEssentialEnough == true then
		isEssentialEnough = false
		signalHandle(isEssentialEnough)
	end
end

local function checkCraftables()
	for i = #requestStack, 1, -1 do
		if not craftables[requestStack[i].name] then
			table.insert(errorRequestStack, table.remove(requestStack, i))
			errorRequestStack[#errorRequestStack].errInfo = "uncraftable"
		end
	end
end

local Cpus
local idleCpus = {}
local function hasCpus()
	if #Cpus ~= 0 then
		return true
	else
		print("未检测到可用CPU")
		os.sleep(3) os.execute('cls')
		return false
	end
end

local function getCpusWithTagName()
	Cpus = {}
	local cpus = controller.getCpus()
	for i = 1, #cpus do
		if not config.TagName or cpus[i].name == config.TagName then
			table.insert(Cpus, 
				{ isBusy = cpus[i].cpu.isBusy, name = cpus[i].name })
		end
	end
end

local function checkCpuIdle()
	if #idleCpus == 0 then
		repeat
			getCpusWithTagName()
		until hasCpus()
		idleCpus = Cpus
	end
	for i =  #idleCpus, 1, -1 do
		if idleCpus[i].isBusy() then
			table.remove(idleCpus, i)
		end
	end
end

local function whenRequestHandleFailed(info)
	if info == "request failed (missing resources?)" then
		table.insert(errorRequestStack, table.remove(requestStack, 1))
		errorRequestStack[#errorRequestStack].errInfo = "missing resources"
	else
		table.insert(requestStack, table.remove(requestStack, 1))
	end
end

local function whenRequestHandleSucceeded(result)
	table.remove(idleCpus, 1)
	table.insert(craftingEssential, table.remove(requestStack[1]))
	local this = craftingEssential[#craftingEssential]
	this.isDone, this.isCanceled = result.isDone, result.isCanceled
end

local function requestHandle()
	checkCraftables()
	checkCpuIdle()
	while #requestStack > 0 and #idleCpus ~= 0 
		and #craftingEssential < config.maxRequestNum do
		local result = craftables[requestStack[1].name](requestStack[1].num, false, idleCpus[1].name)
		local hasFailed, info = result.hasFailed
		if hasFailed then
			whenRequestHandleFailed(info)
		else
			whenRequestHandleSucceeded(result)
		end
	end
end

local Info
local isInfoChanged
local function decodeErrStack()
	Info = { ["uncraftable"] = {}, ["missing resources"] = {} }
	for i = 1, #errorRequestStack do
		table.insert(Info[errorRequestStack[i].errInfo], errorRequestStack[i].name)
	end
end 

local gpu = component.gpu
local length, height = gpu.getViewport()
local maxRows = math.floor( ( height - 6 ) / 2 )
local maxLens = length - 2

local function draw(x, y, len, row, info)
	local posX = x
	for k in pairs(info) do
		if x + string.len("  • " .. k) > len then
			x = posX
			y = y + 1
			if y > row then 
				return nil
			end
		end
		gpu.set(x, y, "  • " .. k)
		x = x + string.len("  • " .. k)
	end
end

local function display()
	gpu.fill(1, 2, length, height, " ")
	gpu.set(1 ,5, "---以下源质缺少样板---")
	draw(1, 6, maxLens, maxRows, Info["uncraftable"])
	gpu.set(1, 6 + maxRows, "---以下源质缺少原料---")
	draw(1, 7 + maxRows, maxLens, maxRows, Info["missing resources"])
	gpu.set(length - 12, height - 3, "源质是否充足")
	gpu.set(length - 8, height - 1, tostring(isEssentialEnough))
end

local function main()
	init()
	while true do
		checkEssentialEnough()
		sendSignal()
		requestHandle()
		decodeErrStack()
		display()
		os.sleep(5)
	end
end
main()