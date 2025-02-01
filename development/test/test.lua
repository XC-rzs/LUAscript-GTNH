local function test_performance()
    local a = 12157665459056928801
    local n = 40
    local start_time = os.clock()
    for k = 1, n do
        for k = 1, n do
            for k = 1, n do
                for i = 1, n do
                    local result = a // 3 * 2
                end
                a = 12157665459056928801
            end
        end
    end
    local end_time = os.clock()
    print("a // 3 * 2:", end_time - start_time)

    start_time = os.clock()
    for k = 1, n do
        for k = 1, n do
            for k = 1, n do
                for i = 1, n do
                    local result = a - a // 3
                end
                a = 12157665459056928801
            end
        end
    end
    end_time = os.clock()
    print("a - a // 3:", end_time - start_time)
end

test_performance()