
c1 = coroutine.create(function() result = {} result.test = 1 while true do coroutine.yield() print(result.test) result.test = result.test + 1 if result.test > 5 then result = nil end end end)
c2 = coroutine.create(function() while true do print("c2") coroutine.yield() end end)
local coroutines = { c1, c2 }

while true do
    for i, co in ipairs(coroutines) do
        if coroutine.status(co) ~= "dead" then
            local status, err = coroutine.resume(co)
            if not status then
                print("Error in coroutine " .. i .. ": " .. err)
            end
        end
        os.sleep(2)
    end
end