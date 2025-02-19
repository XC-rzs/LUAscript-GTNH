local component = require("component")
local gpu = component.gpu
local controller = component.me_controller

-- 可供配置的部分
local minReserve = 2048	-- 所有源质的最低储量
local Num_perRequest = 2048 -- 每次请求的数量
local signalOutput = sides.top -- 源质不足时红石信号在红石IO端口输出的方向
local TagName = "InfusionCPU"	-- 设置被用于源质下单的CPU的名称
-- 设置特定源质的缓存量
local IndividualEssReserve = {
	...
}

local infoList = {["无样板"]={},["未命名"]={},["无原料"]={},["ableToInfution"]={}}
local length,height = gpu.getViewport()
local maxRows = math.floor((height - 6)/2)
local maxLens = length - 2
local craftingList = {}
local infoChange = true

local function getEssCraftable()
	local filter,list = {name = "thaumicenergistics:crafting.aspect"},{}
	for _, v in pairs(controller.getCraftables(filter)) do
		list[v.getItemStack().aspect] = v.request
	end
	return list
end

local function changInfo(typeStr,nameStr,status)
	if infoList[typeStr][nameStr] ~= status then
		infoChange = true
		infoList[typeStr][nameStr] = status
	end
end

local function getUsableCPU()
	local allCPU,hasNamedCPU = controller.getCpus(),false
	for n = 1, #allCPU do
		if allCPU[n].name:match("^"..TagName) == TagName then
			hasNamedCPU = true
			changInfo("未命名","cpu",0)
			if allCPU[n].busy == false then
				return allCPU[n]
			end
		end
	end
	if not hasNamedCPU then
		changInfo("未命名","cpu",true)
	end
end

local function requestEss(name,NUM)
	ableToInfution = false
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
		changInfo("无样板",name,nil)
		local cpu = getUsableCPU()
		if cpu then
			craftingList[name] = listRequest[name](NUM,nil,cpu.name)
			if craftingList[name].hasFailed() then
				changInfo("无原料",name,1)
				craftingList[name] = nil
			else
				changInfo("无原料",name,nil)
				return nil
			end
		end
	else
		changInfo("无样板",name,1)
	end
end

local function requestMissingEss(allEss)
	local list = {}
    for _, v in pairs(allEss) do
    	list[v.label:match("^%S+"):lower()] = true
    end
    for k,_ in pairs(listRequest) do
    	if not list[k] then
			requestEss(k,1)
    		return nil
    	end
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

local function DisplayInformation()
	if infoChange then
		gpu.fill(1,2,length,height," ")
		if infoList["未命名"]["cpu"] == true then
			gpu.set(1,3," • ERROR: 缺少特殊名称的CPU，无法下单！")
		end
		gpu.set(1,5,"---以下源质缺少样板---")
		showInfoInBounds(1,6,maxLens,maxRows,infoList["无样板"])
		gpu.set(1,6 + maxRows,"---以下源质缺少原料---")
		showInfoInBounds(1,7 + maxRows,maxLens,maxRows,infoList["无原料"])
		gpu.set(length - 12,height - 3,"源质是否充足")
		gpu.set(length - 8,height - 1,tostring(ableToInfution))
	end
	infoChange= false
end

local function hasRSIO()
	for _,_ in pairs(component.list("redstone")) do
		return true
	end
end 

local function main()
	listRequest = getEssCraftable()
	os.execute("cls")
	while true do
		os.sleep(1)
		repeat
			ableToInfution = true
			local currentEss = controller.getEssentiaInNetwork()
			requestMissingEss(currentEss)
			for _, v in pairs(currentEss) do
				local name = v.label:match("^%S+"):lower()
				local finalMinReserve = IndividualEssReserve[name]
				if not finalMinReserve then
					finalMinReserve = minReserve
				end
				if v.amount < finalMinReserve then
					requestEss(name,Num_perRequest)
				end
			end
			changInfo("ableToInfution","content",ableToInfution)
			if hasRSIO() then
				if ableToInfution then
					component.redstone.setOutput(signalOutput,16)
				else
					component.redstone.setOutput(signalOutput,0)
				end
			end
			DisplayInformation()
		until ableToInfution == true
	end
end

main()