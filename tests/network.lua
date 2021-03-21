
require("network/channel")

require("network/platform/mock/modem")
require("network/platform/mock/os")

testNetworkChannel = function(aCheck)
    local createMessageQueue = function(aIChannel)
        local messageQueue = {}

        local callback = function(...)
            local args = {...}

            for _, arg in ipairs(args) do
                table.insert(messageQueue, arg)
            end
        end

        aIChannel.addCallback(callback)
        return messageQueue
    end

    local networkMock = networkMockCreate()

    local iModemA = networkMock.modemCreate("modemA")
    local iModemB = networkMock.modemCreate("modemB")
    
    local iChannelA = channelCreate(iModemA)
    local iChannelB = channelCreate(iModemB)
    
    local channel100A = iChannelA.open(100)
    local channel200A = iChannelB.open(200)
    local channel100B = iChannelB.open(100)
    
    local queue100A = createMessageQueue(channel100A)
    local queue200A = createMessageQueue(channel200A)
    local queue100B = createMessageQueue(channel100B)

    channel100A.broadcast("A")
    channel100B.send("modemA", "B")
    channel100B.send("modemC", "C")
    channel200A.broadcast("D")
    
    aCheck(#queue100A == 3,             #queue100A .. " == 3")
    aCheck(#queue200A == 0,             #queue200A .. " == 0")
    aCheck(#queue100B == 3,             #queue100B .. " == 3")
    
    aCheck(queue100A[1] == 100,         tostring(queue100A[1]) .. " == 100")
    aCheck(queue100A[2] == "modemB",    tostring(queue100A[2]) .. " == \"modemB\"")
    aCheck(queue100A[3] == "B",         tostring(queue100A[3]) .. " == \"B\"")
    aCheck(queue100B[1] == 100,         tostring(queue100B[1]) .. " == 100")
    aCheck(queue100B[2] == "modemA",    tostring(queue100A[2]) .. " == \"modemA\"")
    aCheck(queue100B[3] == "A",         tostring(queue100A[3]) .. " == \"A\"")
end
