
require("tests/network")

local config = {
    throwError = false
}

local countGlobalTests = 0
local countGlobalSuccess = 0

local runTest = function(aTest, aTestName)

    local countTests = 0
    local countSuccess = 0
    local countFailure = 0
    local lastLabel = "[TEST START]"

    local checkFunc = function(aResult, aLabel)
        countTests = countTests + 1
        lastLabel = aLabel

        if aResult then
            countSuccess = countSuccess + 1

            return
        end

        countFailure = countFailure + 1
        print("  Check failed: " .. aLabel .. "(" .. countTests .. ")")
    end

    print(aTestName .. ":")

    local executor = pcall

    if config.throwError then
        executor = function(aFunc, ...)
            aFunc(...)

            return true
        end
    end

    if executor(aTest, checkFunc) then
        print("  Tests passed: " .. countSuccess .. "/" .. countTests)
    else
        print("  Tests threw an error after " .. lastLabel .. "(" .. countTests .. ")")
    end

    countGlobalTests = countGlobalTests + countTests
    countGlobalSuccess = countGlobalSuccess + countSuccess
end

runTest(testNetworkChannel,         "NetworkChannel")

print("Total tests passed: " .. countGlobalSuccess .. "/" .. countGlobalTests)