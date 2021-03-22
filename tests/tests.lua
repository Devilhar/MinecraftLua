
require("tests/io/testsChannel")
require("tests/io/testsSafeConnection")

local config = {
    throwError = false
}

local countGlobalTests = 0
local countGlobalSuccess = 0

local runTests = function(aTestData)
    local countGroupTests = 0
    local countGroupSuccess = 0

    local runTest = function(aTest, aTestName)
        local countTests = 0
        local countSuccess = 0
        local lastLabel = "[TEST START]"

        local checkFunc = function(aResult, aLabel)
            countGlobalTests = countGlobalTests + 1
            countGroupTests = countGroupTests + 1
            countTests = countTests + 1
            lastLabel = aLabel

            if aResult then
                countGlobalSuccess = countGlobalSuccess + 1
                countGroupSuccess = countGroupSuccess + 1
                countSuccess = countSuccess + 1

                return
            end

            print("    Check failed: " .. aLabel .. "(" .. countTests .. ")")
        end

        print("  " .. aTestName)

        local executor = pcall

        if config.throwError then
            executor = function(aFunc, ...)
                aFunc(...)

                return true
            end
        end

        if executor(aTest, checkFunc) then
            print("    Tests passed: " .. countSuccess .. "/" .. countTests)
        else
            print("    Tests threw an error after " .. lastLabel .. "(" .. countTests .. ")")
        end
    end

    print(aTestData.name)
    
    for _, testData in ipairs(aTestData.tests) do
        runTest(testData.test, testData.name)
    end
    
    print("  Group tests passed: " .. countGroupSuccess .. "/" .. countGroupTests)
end

runTests(testsChannel)
runTests(testsSafeConnection)

print()

print("Total tests passed: " .. countGlobalSuccess .. "/" .. countGlobalTests)

if countGlobalSuccess ~= countGlobalTests then
    print()

    print("#ERROR: Test/s failed!")
end
