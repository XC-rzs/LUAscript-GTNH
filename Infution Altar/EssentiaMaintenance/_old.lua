local port = 12306	-- 端口(需与注魔自动化端口相同)
local signalStrength = 256 -- 信号强度(最大为400)
local All_min = 2048	-- 所有源质的最低储量
local Num_perRequest = 2048 -- 每次请求的数量
local TagName = "InfusionCPU"	-- 设置被用于源质下单的CPU的名称
 
local component = require("component")
local gpu = component.gpu
local modem = component.modem
local controller = component.me_controller
 
local function getEssCraftable()
	local EList,i,num = {},0,0
	for k,v in pairs(controller.getCraftables()) do
	 	local currentStack = v.getItemStack() 
	 	if currentStack.aspect then 
	 		EList[currentStack.aspect] = v
	 		i = i + 1
	 	end
	 	num = num + 1
	 	gpu.set(1,1,"正在检索源质合成样板中:"..tostring(i).."/"..tostring(num))
 	end
 	os.execute("cls")
 	EList.num = i
	return EList
end
 
local function getMissingEss()
	local list = controller.getEssentiaInNetwork()
	local name_Ect = {}
	for k,_ in pairs(Ect) do
		if k ~= "num" then
    		table.insert(name_Ect,k)
    	end
    end
	for i = #name_Ect,1,-1 do
		for n,v in pairs(list) do
			if name_Ect[i] == (v.label:match("^%S+"):lower()) then
				table.remove(name_Ect,i)
				table.remove(list,n)
				break
			end
		end
	end
	return name_Ect[1]
end
 
local function requestEssentia(name,NUM)
	gpu.set(1,1,"正在请求源质"..tostring(name)..".      ")
	massage = false
	::RE::
	for k,v in pairs(processList) do
		if v.isDone() or v.isCanceled() then
			processList[k] = nil
			goto RE
		end
		if k == name then
			return nil
		end
	end
	if Ect[name] then
		gpu.set(1,7,".                                                   ")
		local AEcpus,hasNamedCPU = controller.getCpus(),false
		for n = 1,#AEcpus do
			if AEcpus[n].name:match("^"..TagName) == TagName then
				hasNamedCPU = true
				gpu.set(1,5,".                                           ")
				if not AEcpus[n].busy then
					processList[name] = Ect[name].request(NUM,nil,AEcpus[n].name)
					if processList[name].hasFailed() then
						gpu.set(1,3,"ERROR: 合成"..name.."失败，缺乏原材料！          ")
						processList[name] = nil
						os.sleep(3)
					else
						return nil
					end
				end
			end
		end
		if not hasNamedCPU then
			gpu.set(1,5,"ERROR: 缺少特殊名称的CPU，无法进行下单！          ")
			os.sleep(3)
		end
	else
		gpu.set(1,7,"ERROR: 未查找到源质"..name.."的合成样板          ")
		os.sleep(3)
	end
end
 
-- 判断逻辑
local function mainProcess()
	while true do
		local List = controller.getEssentiaInNetwork()
		massage = true
		if getMissingEss() then
			requestEssentia(getMissingEss(),1)
		end
		for _,v in pairs(List) do
			if v.amount < All_min then
				requestEssentia(v.label:match("^%S+"):lower(),Num_perRequest)
			end
		end
		modem.broadcast(port,massage)
		gpu.set(50,12,"已发送报文  "..tostring(massage).."   ")
	end
end
 
local function main()
	-- 初始化
	os.execute("cls")
	gpu.setViewport(80,25)
	modem.setStrength(signalStrength)
	modem.open(port)
	processList = {}
	Ect = getEssCraftable()
 
	mainProcess()
end
 
main()