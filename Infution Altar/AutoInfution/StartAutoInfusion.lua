sides = require("sides")
component = require("component")
local rs = component.redstone
local data = component.database
local interface = component.me_interface

-- 获取组件代理(需要更改)
local ts = component.proxy("725eb724-fc4c-42df-942a-4d167a633bec")		-- 基座旁的转运器
local ts_ap = component.proxy("eee8e7f8-07fe-4a0a-ac43-404f9ad432eb")	-- 注魔爪旁的转运器

-- 各部件方向(可能需要更改)
local directions = {
	RM = sides.east, --符文矩阵方向
	WA = sides.south, --控制世界加速器的红石导管方向
	sideControl = sides.down --输入红石信号控制注魔的面
}

local config = {
	-- 设置注魔最大时间，括号内为时间，单位为s(超出最大时间会报错)
	InfusionMaxTime = (5)*72,
	-- 等待原料连续输入的时间(单位为s)
	waitForInputSleepTime = 0.02,
	-- 是否反相控制信号(默认为有信号启动注魔)
	invertSignal = false
}

local function getAddress(str)
	local list = {}
	for k,_ in pairs(component.list(str)) do
		table.insert(list,k)
	end
	return list
end

local function setWAstatus(num)
	rs.setOutput(directions.WA,num)
	if num == 1 then os.sleep(0.5) end 	-- 过滤掉控制世界加速器的红石信号对注魔爪的影响
end

local function sendPulse()
    rs.setOutput(directions.RM, 15)
    os.sleep(0.05)
    rs.setOutput(directions.RM, 0)
end

local function printAndClear(str,t)
	print(str) os.sleep(t) os.execute("cls")
end

local function isWandsAspectsEnough()
	while not ts_ap.getStackInSlot(sides.down,1) do
		printAndClear("ERR: 法杖缺失，请在注魔爪内放置法杖",3)
	end
	::RESTART::
	local ap = ts_ap.getStackInSlot(sides.down,1)
	for i=1, 6 do
		if ap.aspects[i].amount < 1000 then
			printAndClear("ERR: 法杖内要素不足，请检查魔力中继器是否正常工作",3) 
			goto RESTART
		end
	end
	sendPulse()
end

local function ExportResidual(list)
	local MarkedSlotsNum,num,nextNum = #list
	::RE::
	if #list > 9 then
		num = 9
		nextNum = #list - 9
	else
		num,nextNum = #list,1
	end
	for i=1, num do
		data.set(i,list[i].name,list[i].damage)
	end
	if nextNum == 1 then ts.transferItem(sides.top,directions.RM) end
	for i=1, num do
		interface.setInterfaceConfiguration(i,address_database,i,list[i].maxSize)
	end
	while next(interface.getItemsInNetwork(),nextNum) do end
	if nextNum == 1 then
		for i=1, MarkedSlotsNum do
			interface.setInterfaceConfiguration(i)
		end
		ts.transferItem(directions.RM,sides.top)
	else
		MarkedSlotsNum = 9
		list = interface.getItemsInNetwork()
		goto RE
	end
end

local function reportErrAndWait(currentStack)
	hasError = true
	setWAstatus(0)
	ts.transferItem(directions.RM,sides.down)
	print("ERR：注魔 "..currentStack.label.." (被注魔物)时超时\n可能的原因：1- 输入物品不构成配方；2- 源质不足\n")
	print("已将被注魔物抽回主网，等待排障中.....\n")
	print([[按下 "Enter" 继续注魔]])
	io.read()
	setWAstatus(1)
	print("\n正在输出基座上物品")
	ExportResidual(ItemInSubnet)
	os.execute("cls")
end

local function isInfusingFinished(currentStack)
	local startTime = os.time()
	local cachedlabel = currentStack.label
	repeat
		currentStack = ts.getStackInSlot(directions.RM,1)
		ItemInSubnet = interface.getItemsInNetwork()
		if os.time() - startTime > config.InfusionMaxTime then
			reportErrAndWait(currentStack)
			break
		end
	until currentStack.label ~= cachedlabel or #ItemInSubnet == 1
	return currentStack
end

local function Output(currentStack)
	if not hasError then
		for i = 1, currentStack.size do
			ts.transferItem(directions.RM,sides.down,1)
		end
	end
	hasError = false
end

local function isResidueInSubnet()
	ItemInSubnet = interface.getItemsInNetwork()
	if next(ItemInSubnet) then
		ExportResidual(ItemInSubnet)
	end
end

local function hasSignal()
	if rs.getInput(directions.sideControl) == 0 then
		return false else return true
	end
end

local function allowInfution()
	if config.invertSignal == hasSignal() then
		setWAstatus(0)
		print("已被外部信号暂停，等待中....")
		while config.invertSignal == hasSignal() do os.sleep(1) end
		os.execute("cls")
		setWAstatus(1)
	end
end

local function main()
	address_database = getAddress("database")[1]
	while not address_database do
		printAndClear("ERR:适配器中缺少数据库！",3)
		address_database = getAddress("database")[1]
	end
	while true do
		os.sleep(0.5)
		local currentStack = ts.getStackInSlot(directions.RM,1)
		if currentStack then
			setWAstatus(1)
			repeat
				repeat
					repeat
						allowInfution()
						isWandsAspectsEnough()
						currentStack = isInfusingFinished(currentStack)
						Output(currentStack)
						currentStack = ts.getStackInSlot(directions.RM,1)
					until not currentStack
					os.sleep(config.waitForInputSleepTime)
					currentStack = ts.getStackInSlot(directions.RM,1)
				until not currentStack
				isResidueInSubnet()
				currentStack = ts.getStackInSlot(directions.RM,1)
			until not currentStack
			setWAstatus(0)
		end
	end
end

main()