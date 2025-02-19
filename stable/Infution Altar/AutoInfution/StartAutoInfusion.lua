local event = require "event"
local computer = require "computer"
local component = require "component"

local config = {
	maxInfusionSecond = 10,
	modemPort = 12306
}

while next(component.list("redstone")) == nil do
	print("未检测到红石IO端口，请检查")
	os.sleep(3) os.execute("cls")
end
while next(component.list("me_interface")) == nil do
	print("未检测到用于输出残留物品的me接口，请检查")
	os.sleep(3) os.execute("cls")
end
local interface = component.me_interface

local enableSignal = {fromModem = true, fromRedstone = true}
local componentProxy = {
	WorldAccelerator = {},
	transposer = {
		forArcanePedestal = false,
		forInfusionClaw = false
	},
	databaseAddress = false
}
local directions = {ArcanePedestal = false, InfutionClaw = false, Interface = false, chest = false}

local ErrList = {}
local function printErr()
	for i = 1, #ErrList do
		print(ErrList[i])
	end
	ErrList = {}
	print("请按Enter键继续.....")
	io.read()
	os.execute("cls")
end

local function getComponentProxy(name)
	local tbl = {}
	for address in pairs(component.list(name)) do
		table.insert(tbl, component.proxy(address))
	end
	return tbl
end

local function registerEventListen()
	event.listen("redstone_changed", function(eventType, address, sourceSide, lastSignal, currentSignal)
		if currentSignal == 0 then
			enableSignal.fromRedstone = true
		else
			enableSignal.fromRedstone = false
		end
	end)
	if next(component.list("modem")) ~= nil then
		component.modem.open(config.modemPort)
		event.listen("modem_message", function(eventType, selfAddress, sourceAddress, port, distance, massage)
			enableSignal.fromModem = massage
		end)
	end
end

local function getDatabaseAddress()
	local tbl = component.list("database")
	if next(tbl) ~= nil then
		for address in pairs(tbl) do
			componentProxy.databaseAddress = address
		end
	else
		table.insert(ErrList, "未检测到数据库，请在适配器中放入数据库")
	end
end

local function getInterfaceAndChestDirction()
	for i = 0, 5 do
		local name = componentProxy.transposer.forArcanePedestal.getInventoryName(i)
		if name == "tile.appliedenergistics2.BlockInterface" or name == "tile.fluid_interface" then
			directions.Interface = i
		elseif name == "tile.chest" then
			directions.chest = i
		end
	end
end

local function getTransposerProxy()
	for _, proxy in pairs(getComponentProxy("transposer")) do
		for i = 0, 5 do
			if proxy.getInventoryName(i) == "tile.blockStoneDevice" then
				componentProxy.transposer.forArcanePedestal = proxy
				directions.ArcanePedestal = i
				getInterfaceAndChestDirction()
			elseif proxy.getInventoryName(i) == "tile.BlockInfusionClaw" then
				componentProxy.transposer.forInfusionClaw = proxy
				directions.InfutionClaw = i
			end
		end
	end
end

local function getWorldAcceleratorProxy()
	componentProxy.WorldAccelerator = {}
	for _, proxy in pairs(getComponentProxy("gt_machine")) do
		table.insert(componentProxy.WorldAccelerator, proxy)
	end
end

local function checkInitSuccess()
	if not componentProxy.transposer.forArcanePedestal then
		table.insert(ErrList, "未检测到中心奥术基座旁的转运器")
	end
	if not directions.Interface then
		table.insert(ErrList, "未检测到输出产物的me接口")
	end
	if not directions.chest then
		table.insert(ErrList, "未检测到存放占位符的箱子")
	end
	if not componentProxy.transposer.forInfusionClaw then
		table.insert(ErrList, "未检测到注魔爪旁的转运器")
	end
	if #componentProxy.WorldAccelerator ~= 2 then
		table.insert(ErrList, "未检测到世界加速器 或 接入OC的加速器数量不为2")
	end
	if next(ErrList) == nil then
		return true
	else
		printErr()
		return false
	end
end

local function setWorldAcceleratorStatus(boolean)
	for i = 1, #componentProxy.WorldAccelerator do
		componentProxy.WorldAccelerator[i].setWorkAllowed(boolean)
	end
	os.sleep(0.5)
end

local function init()
	registerEventListen()
	repeat
		getDatabaseAddress()
		getTransposerProxy()
		getWorldAcceleratorProxy()
	until checkInitSuccess()
	setWorldAcceleratorStatus(false)
	print("初始化成功！\n等待注魔中.....")
end

local function getStackInArcanePedestal()
	return componentProxy.transposer.forArcanePedestal.getStackInSlot(directions.ArcanePedestal, 1)
end

local function getStackInInfusionClaw()
	return componentProxy.transposer.forInfusionClaw.getStackInSlot(directions.InfutionClaw, 1)
end

local function checkWandsAspects()
	local wands = getStackInInfusionClaw()
	while not wands do
		table.insert(ErrList, "注魔爪内未检测到法杖，请放入法杖")
		return nil
	end
	for i = 1, 6 do
		if wands.aspects[i].amount < 1000 then
			table.insert(ErrList, "法杖内要素不足，请检查魔力中继器是否正常工作") 
			break
		end
	end
end

local function checkPreconditionsForInfusion()
	event.pull(0.01)
	if enableSignal.fromRedstone == false then
		table.insert(ErrList, "注魔被外部红石信号暂停")
	end
	if enableSignal.fromModem == false then
		table.insert(ErrList, "注魔被外部网络信号暂停")
	end
	checkWandsAspects()
	if next(ErrList) ~= nil then
		for i = 1, #ErrList do
			print(ErrList[i])
		end
		ErrList = {}
		os.sleep(3)
		os.execute("cls")
		checkPreconditionsForInfusion()
	end
end 

local function whenOvertime(currentStack)
	componentProxy.transposer.forArcanePedestal.transferItem(directions.ArcanePedestal, directions.Interface, 1)
	setWorldAcceleratorStatus(false)
	ErrList = {
		"注魔 " .. currentStack.label .. " (被注魔物)时超时\n可能的原因： 1- 输入物品不构成配方； 2- 源质不足",
		"已将被注魔物抽回主网，等待排障中....."
	}
	printErr()
	setWorldAcceleratorStatus(true)
end

local function startInfution()
    component.redstone.setOutput(directions.ArcanePedestal, 15)
    os.sleep(0.05)
    component.redstone.setOutput(directions.ArcanePedestal, 0)
end

local function whenInfusion(currentStack)
	local startTime = computer.uptime()
	local cachedlabel = currentStack.label
	repeat
		if computer.uptime() - startTime > config.maxInfusionSecond then
			whenOvertime(currentStack)
		end
		currentStack = getStackInArcanePedestal()
	until currentStack == nil or currentStack.label ~= cachedlabel or #interface.getItemsInNetwork() == 1
	return currentStack
end

local function outputProduct(currentStack)
	if currentStack then
		for i = 1, currentStack.size do
			componentProxy.transposer.forArcanePedestal.transferItem(directions.ArcanePedestal, directions.Interface, 1)
		end
	end
end

local function ExportReamainingItems(list)
	local MarkedSlotsNum,num,nextNum = #list
	::RESTART_EXPORT_REAMAINING_ITEMS::
	if #list > 9 then
		num = 9
		nextNum = #list - 9
	else
		num, nextNum = #list, 1
	end
	for i = 1, num do
		component.database.set(i, list[i].name, list[i].damage)
	end
	if nextNum == 1 then 
		while componentProxy.transposer.forArcanePedestal.transferItem(directions.chest, directions.ArcanePedestal) == 0
		and not getStackInArcanePedestal() do
			print("占位符丢失！请在箱子内重新放入占位符") os.sleep(3) os.execute("cls")
		end
	end
	for i = 1, num do
		interface.setInterfaceConfiguration(i, componentProxy.databaseAddress, i, list[i].maxSize)
	end
	while next(interface.getItemsInNetwork(), nextNum) do end
	if nextNum == 1 then
		for i = 1, MarkedSlotsNum do
			interface.setInterfaceConfiguration(i)
		end
		componentProxy.transposer.forArcanePedestal.transferItem(directions.ArcanePedestal, directions.chest)
	else
		MarkedSlotsNum = 9
		list = interface.getItemsInNetwork()
		goto RESTART_EXPORT_REAMAINING_ITEMS
	end
end

local function processRemainingItemsInSubnet()
	if getStackInArcanePedestal() then
		return nil
	end
	local ItemInSubnet = interface.getItemsInNetwork()
	if next(ItemInSubnet) ~= nil then
		ExportReamainingItems(ItemInSubnet)
	end
end

local function startInfusion(currentStack)
	setWorldAcceleratorStatus(true)
	repeat
		repeat
			checkPreconditionsForInfusion()
			startInfution()
			currentStack = whenInfusion(currentStack)
			outputProduct(currentStack)
			currentStack = getStackInArcanePedestal()
		until not currentStack
		os.sleep(0.05)
		processRemainingItemsInSubnet()
		currentStack = getStackInArcanePedestal()
	until not currentStack
	setWorldAcceleratorStatus(false)
end

local function main()
	init()
	while true do
		local currentStack = getStackInArcanePedestal()
		if currentStack then
			startInfusion(currentStack)
		end
		os.sleep(3)
	end
end
main()