local port = 12306	-- 端口(需与注魔自动化端口相同)
local signalStrength = 256 -- 信号强度(最大为400)
local minReserve = 2048	-- 所有源质的最低储量
local Num_perRequest = 2048 -- 每次请求的数量
local TagName = "InfusionCPU"	-- 设置被用于源质下单的CPU的名称

local component = require("component")
local floor = require("math").floor
local gpu = component.gpu
local modem = component.modem
local controller = component.me_controller

local ErrList = {["无样板"]={},["未命名"]={},["无原料"]={}}
local length,height = gpu.getViewport()
local maxRows = floor((height - 6)/2)
local maxLens = length - 2
local craftingList = {}
local ErrChange = true

local function getEssCraftable()
	local filter,list = {name = "thaumicenergistics:crafting.aspect"},{}
	for _, v in pairs(controller.getCraftables(filter)) do
		list[v.getItemStack().aspect] = v.request
	end
	return list
end

local function getMissingEss()
	local list = controller.getEssentiaInNetwork()
	local allEss = {}
    for _, v in pairs(list) do
    	allEss[v.label:match("^%S+"):lower()] = true
    end
    for k,_ in pairs(listRequest) do
    	if not allEss[k] then
    		return k 
    	end
    end
end

local function changeErr(typeStr,nameStr,statusNum)
	if ErrList[typeStr][nameStr] ~= statusNum then
		ErrChange = true
		ErrList[typeStr][nameStr] = statusNum
	end
end

local function getUsableCPU()
	local allCPU,hasNamedCPU = controller.getCpus(),false
	for n = 1, #allCPU do
		if allCPU[n].name:match("^"..TagName) == TagName then
			hasNamedCPU = true
			changeErr("未命名","cpu",0)
			if allCPU[n].busy == false then
				return allCPU[n]
			end
		end
	end
	if not hasNamedCPU then
		changeErr("未命名","cpu",1)
	end
end

local function requestEss(name,NUM)
	massage = false
	::RE::
	for k, v in pairs(craftingList) do
		if v.isDone() or v.isCanceled() then
			craftingList[k] = nil
			goto RE
		end
		if k == name then
			return nil
		end
		gpu.set(1,1," • 正在请求源质[ "..tostring(name).." ]      ")
	end
	if listRequest[name] then
		changeErr("无样板",name,nil)
		local cpu = getUsableCPU()
		if cpu then
			craftingList[name] = listRequest[name](NUM,nil,cpu.name)
			if craftingList[name].hasFailed() then
				changeErr("无原料",name,1)
				craftingList[name] = nil
			else
				changeErr("无原料",name,nil)
				return nil
			end
		end
	else
		changeErr("无样板",name,1)
	end
end

local function showInfoInBounds(x,y,lens,rows,info)
	local posX = x
	for k,_ in pairs(info) do
		if x + string.len("  • "..k) > lens then
			x = posX
			y = y + 1
			if y > rows then 
				return nil
			end
		end
		gpu.set(x,y,"  • "..k)
		x = x + string.len("  • "..k)
	end
end

local function showTheMassage()
	gpu.fill(1,2,length,height," ")
	gpu.set(length - 10,height - 3,"已发送报文")
	gpu.set(length - 8,height - 1,tostring(massage))
end

local function DisplayInformation()
	if massage == false then
		if ErrChange then
			showTheMassage()
			if ErrList["未命名"]["cpu"] == 1 then
				gpu.set(1,3," • ERROR: 缺少特殊名称的CPU，无法下单！")
			end
			gpu.set(1,5,"---以下源质缺少样板---")
			showInfoInBounds(1,6,maxLens,maxRows,ErrList["无样板"])
			gpu.set(1,6 + maxRows,"---以下源质缺少原料---")
			showInfoInBounds(1,7 + maxRows,maxLens,maxRows,ErrList["无原料"])
		end
	else
		showTheMassage()
	end
	ErrChange = false
end

local function main()
	-- 初始化
	listRequest = getEssCraftable()
	modem.setStrength(signalStrength)
	modem.open(port)
	
	os.execute("cls")
	while true do
		os.sleep(1)
		repeat
			massage = true
			if getMissingEss() then
				requestEss(getMissingEss(),1)
			end
			for _, v in pairs(controller.getEssentiaInNetwork()) do
				if v.amount < minReserve then
					requestEss(v.label:match("^%S+"):lower(),Num_perRequest)
				end
			end
			modem.broadcast(port,massage)
			DisplayInformation()
		until massage == true
	end
end

main()