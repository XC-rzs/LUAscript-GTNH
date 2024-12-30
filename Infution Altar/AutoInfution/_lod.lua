io = require("io")
sides = require("sides")
event = require("event")
component = require("component")
local rs = component.redstone
local data = component.database
local modem = component.modem
local interface = component.me_interface

-- 获取组件代理(需要更改)
local ts = component.proxy("725eb724-fc4c-42df-942a-4d167a633bec")		-- 基座旁的转运器
local ts_ap = component.proxy("eee8e7f8-07fe-4a0a-ac43-404f9ad432eb")	-- 注魔爪旁的转运器

-- 各部件方向(可能需要更改)
local directions = {
	RM = sides.east, --符文矩阵方向
	WA = sides.south, --控制世界加速器的红石导管方向
}

local config = {
	-- 设置注魔最大时间，括号内为时间，单位为s(超出最大时间会报错)
	InfusionMaxTime = (5)*20,
	-- 等待原料连续输入的时间(单位为s)
	waitForInputSleepTime = 0.02,
	-- 端口(需与缓存指令器端口相同)
	port = 12306,
	-- 是否启用源质充足判断
	EnableEssentiaJudgment = true
}

local function getAddress(str)
	local list_address = {}
	for key,value in pairs(component.list(str)) do
		table.insert(list_address,key)
	end
	return list_address
end

local function transToProxy(address)
	local list_proxy = {}
	for k,v in pairs(address) do
		table.insert(list_proxy,component.proxy(v))
	end
	if list_proxy == {} then list_proxy = nil end 
	return list_proxy
end

local function setWAstatus(b,proxy)
	if proxy then
		for k,v in pairs(proxy) do
			v.setWorkAllowed(b)
		end
	elseif b == true then
		rs.setOutput(directions.WA,1)
		os.sleep(2)	-- 过滤掉控制世界加速器的红石信号对注魔爪的影响
	else 
		rs.setOutput(directions.WA,0)
	end
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
	local ap = ts_ap.getStackInSlot(sides.down,1)
	while not ap do
		printAndClear("ERROR: 法杖缺失，请在注魔爪内放置法杖",3)
		ap = ts_ap.getStackInSlot(sides.down,1)
	end
	::RESTART::
	for i=1,6 do
		if ap.aspects[i].amount < 1000 then
			printAndClear("ERROR: 法杖内要素不足，请检查魔力中继器是否正常工作",3) 
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
	for i=1,num do
		data.set(i,list[i].name,list[i].damage)
	end
	if nextNum == 1 then ts.transferItem(sides.top,directions.RM) end
	for i=1,num do
		interface.setInterfaceConfiguration(i,address_database,i,list[i].maxSize)
	end
	while next(interface.getItemsInNetwork(),nextNum) do end
	if nextNum == 1 then 
		data.clear(1)
		for i=1,MarkedSlotsNum do
			interface.setInterfaceConfiguration(i,address_database,1)
		end
		ts.transferItem(directions.RM,sides.top)
	else
		MarkedSlotsNum = 9
		list = interface.getItemsInNetwork()
		goto RE
	end
end

local function isInfusingFinished(currentStack)
	local time = 0
	local cachedlabel = currentStack.label
	repeat
		currentStack = ts.getStackInSlot(directions.RM,1)
		ItemInSubnet = interface.getItemsInNetwork()
		time = time + 1
		if time > config.InfusionMaxTime then
			hasError = true
			setWAstatus(false,proxy_WA)
			ts.transferItem(directions.RM,sides.down)
			print("ERROR：注魔 "..currentStack.label.." (被注魔物)时超时\n可能的原因：1- 输入物品不构成配方；2- 源质不足\n")
			print("已将被注魔物抽回主网，等待排障中.....\n")
			print([[按下 "Enter" 继续注魔]])
			io.read()
			setWAstatus(true,proxy_WA)
			print("\n正在输出基座上物品")
			ExportResidual(ItemInSubnet)
			os.execute("cls")
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

local function isEssentiaEnough()
	if config.EnableEssentiaJudgment == true then
		_, _, _, _, _, massage = event.pull(0.1,"modem_message")
		if massage == nil then
			lsct = lsct + 1
			if lsct == 3 then
				print("可能的错误：未接收到报文！")
			end
		else
			lsct = 0
			ableToStart = massage
		end
		if not ableToStart then
			setWAstatus(false,proxy_WA)
			print("源质不足，等待合成中....")
			while not ableToStart do
				os.sleep(1)
				_, _, _, _, _, ableToStart = event.pull("modem_message")
			end
			os.execute("cls")
			setWAstatus(true,proxy_WA)
		end
	end
end

local function MainProcess()
	local currentStack = ts.getStackInSlot(directions.RM,1)
	if currentStack then
		setWAstatus(true,proxy_WA)
		repeat
			repeat
				repeat
					isEssentiaEnough()
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
		setWAstatus(false,proxy_WA)
	end
end

local function main()
	if config.EnableEssentiaJudgment == true then
		modem.open(config.port)
	end
	address_database,lsct = getAddress("database")[1],0
	proxy_WA = transToProxy(getAddress("gt_machine"))
	setWAstatus(false,proxy_WA)
	while true do
		os.sleep(0.5)
		MainProcess()
	end
end

main()