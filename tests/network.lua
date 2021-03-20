
require("network/channel")
require("network/safeConnection")

require("network/platform/mock/modem")
require("network/platform/mock/os")

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

-- iChannel

testNetworkChannel = function(aCheck)
    local networkMock = networkMockCreate()

    local iModemA = networkMock.modemCreate("modemA")
    local iModemB = networkMock.modemCreate("modemB")
    
    local iChannelA = channelCreate(iModemA)
    local iChannelB = channelCreate(iModemB)
    
    local channel100A = iChannelA.open(100)
    local channel200A = iChannelA.open(200)
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

-- iSafeConnectionConnector

local setupChannelSockets = function(...)
    local channelsData = {...}
    local channelSockets = {}
    local networkMock = networkMockCreate()

    for i, channelData in ipairs(channelsData) do
        local iModem = networkMock.modemCreate(channelData.address)
        
        local iChannel = channelCreate(iModem)
        
        local channelSocket = iChannel.open(channelData.port)

        channelSockets[i] = channelSocket
    end

    return table.unpack(channelSockets)
end

local connectorSetupDataClient = {
    address = "modemClient",
    port = 300
}
local connectorSetupDataServer = {
    address = "modemServer",
    port = 300
}

testNetworkSafeConnectionClientMessage = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)
    local queueServer = createMessageQueue(channelSocketServer)
    
    local countConnect  = 0
    local countClosed   = 0
    local countMessage  = 0
    local messagePayloadsClient = {}

    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
        for _, v in ipairs({...}) do
            table.insert(messagePayloadsClient, v)
        end
    end
    
    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeClientSocket = iSafeConnection.connect(channelSocketClient, "modemServer", onConnect, onClosed, onMessage)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(queueServer[1] == 300,           tostring(queueServer[1]) .. " == 300")
    aCheck(queueServer[2] == "modemClient", tostring(queueServer[2]) .. " == \"modemClient\"")
    aCheck(queueServer[3] == "SC_CON",      tostring(queueServer[3]) .. " == SC_CON")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Accept connection
    channelSocketServer.send("modemClient", "SC_COR", true)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    iSafeClientSocket.send("Hello World")
    
    aCheck(#queueServer == 8,               #queueServer .. " == 8")
    aCheck(queueServer[4] == 300,           tostring(queueServer[4]) .. " == 300")
    aCheck(queueServer[5] == "modemClient", tostring(queueServer[5]) .. " == \"modemClient\"")
    aCheck(queueServer[6] == "SC_MSG",      tostring(queueServer[6]) .. " == \"SC_MSG\"")
    aCheck(queueServer[7] == 1,             tostring(queueServer[7]) .. " == 1")
    aCheck(queueServer[8] == "Hello World", tostring(queueServer[8]) .. " == \"Hello World\"")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Send message response
    channelSocketServer.send("modemClient", "SC_MSR")
    
    aCheck(#queueServer == 8,               #queueServer .. " == 8")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")
    
    -- Send message
    channelSocketServer.send("modemClient", "SC_MSG", 1, "Hello World")
    
    aCheck(#queueServer == 11,                          #queueServer .. " == 11")
    aCheck(queueServer[9] == 300,                       tostring(queueServer[9]) .. " == 300")
    aCheck(queueServer[10] == "modemClient",            tostring(queueServer[10]) .. " == \"modemClient\"")
    aCheck(queueServer[11] == "SC_MSR",                 tostring(queueServer[11]) .. " == \"SC_MSR\"")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 1,                 #messagePayloadsClient .. " == 1")
    aCheck(messagePayloadsClient[1] == "Hello World",   messagePayloadsClient[1] .. " == Hello World")
    
    iSafeClientSocket.send("Hello")
    
    iSafeClientSocket.send("World")
    
    aCheck(#queueServer == 16,                          #queueServer .. " == 16")
    aCheck(queueServer[12] == 300,                      tostring(queueServer[12]) .. " == 300")
    aCheck(queueServer[13] == "modemClient",            tostring(queueServer[13]) .. " == \"modemClient\"")
    aCheck(queueServer[14] == "SC_MSG",                 tostring(queueServer[14]) .. " == \"SC_MSG\"")
    aCheck(queueServer[15] == 2,                        tostring(queueServer[15]) .. " == 2")
    aCheck(queueServer[16] == "Hello",                  tostring(queueServer[16]) .. " == \"Hello\"")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 1,                 #messagePayloadsClient .. " == 1")
    
    mockOs.increaseTime(0.5)
    
    aCheck(#queueServer == 21,                          #queueServer .. " == 21")
    aCheck(queueServer[17] == 300,                      tostring(queueServer[17]) .. " == 300")
    aCheck(queueServer[18] == "modemClient",            tostring(queueServer[18]) .. " == \"modemClient\"")
    aCheck(queueServer[19] == "SC_MSG",                 tostring(queueServer[19]) .. " == \"SC_MSG\"")
    aCheck(queueServer[20] == 2,                        tostring(queueServer[20]) .. " == 2")
    aCheck(queueServer[21] == "Hello",                  tostring(queueServer[21]) .. " == \"Hello\"")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 1,                 #messagePayloadsClient .. " == 1")
    
    mockOs.increaseTime(0.5)
    
    aCheck(#queueServer == 29,                          #queueServer .. " == 29")
    aCheck(queueServer[22] == 300,                      tostring(queueServer[22]) .. " == 300")
    aCheck(queueServer[23] == "modemClient",            tostring(queueServer[23]) .. " == \"modemClient\"")
    aCheck(queueServer[24] == "SC_PNG",                 tostring(queueServer[24]) .. " == \"SC_PNG\"")
    aCheck(queueServer[25] == 300,                      tostring(queueServer[25]) .. " == 300")
    aCheck(queueServer[26] == "modemClient",            tostring(queueServer[26]) .. " == \"modemClient\"")
    aCheck(queueServer[27] == "SC_MSG",                 tostring(queueServer[27]) .. " == \"SC_MSG\"")
    aCheck(queueServer[28] == 2,                        tostring(queueServer[28]) .. " == 2")
    aCheck(queueServer[29] == "Hello",                  tostring(queueServer[29]) .. " == \"Hello\"")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 1,                 #messagePayloadsClient .. " == 1")
    
    -- Send message response
    channelSocketServer.send("modemClient", "SC_MSR")
    
    aCheck(#queueServer == 34,                          #queueServer .. " == 34")
    aCheck(queueServer[30] == 300,                      tostring(queueServer[30]) .. " == 300")
    aCheck(queueServer[31] == "modemClient",            tostring(queueServer[31]) .. " == \"modemClient\"")
    aCheck(queueServer[32] == "SC_MSG",                 tostring(queueServer[32]) .. " == \"SC_MSG\"")
    aCheck(queueServer[33] == 3,                        tostring(queueServer[33]) .. " == 3")
    aCheck(queueServer[34] == "World",                  tostring(queueServer[34]) .. " == \"World\"")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 1,                 #messagePayloadsClient .. " == 1")
    
    -- Send message response
    channelSocketServer.send("modemClient", "SC_MSR")
    
    aCheck(#queueServer == 34,                          #queueServer .. " == 34")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 1,                 #messagePayloadsClient .. " == 1")
end

testNetworkSafeConnectionClientPing = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)
    local queueServer = createMessageQueue(channelSocketServer)
    
    local countConnect  = 0
    local countClosed   = 0
    local countMessage  = 0

    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
    end
    
    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeClientSocket = iSafeConnection.connect(channelSocketClient, "modemServer", onConnect, onClosed, onMessage)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(queueServer[1] == 300,           tostring(queueServer[1]) .. " == 300")
    aCheck(queueServer[2] == "modemClient", tostring(queueServer[2]) .. " == \"modemClient\"")
    aCheck(queueServer[3] == "SC_CON",      tostring(queueServer[3]) .. " == SC_CON")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Accept connection
    channelSocketServer.send("modemClient", "SC_COR", true)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Wait for ping
    mockOs.increaseTime(1)
    
    aCheck(#queueServer == 6,                   #queueServer .. " == 6")
    aCheck(queueServer[4] == 300,               tostring(queueServer[4]) .. " == 300")
    aCheck(queueServer[5] == "modemClient",     tostring(queueServer[5]) .. " == \"modemClient\"")
    aCheck(queueServer[6] == "SC_PNG",          tostring(queueServer[6]) .. " == \"SC_PNG\"")
    aCheck(countConnect == 1,                   countConnect .. " == 1")
    aCheck(countClosed == 0,                    countClosed .. " == 0")
    aCheck(countMessage == 0,                   countMessage .. " == 0")
    
    -- Wait for ping
    mockOs.increaseTime(1)
    
    aCheck(#queueServer == 9,                   #queueServer .. " == 9")
    aCheck(queueServer[7] == 300,               tostring(queueServer[7]) .. " == 300")
    aCheck(queueServer[8] == "modemClient",     tostring(queueServer[8]) .. " == \"modemClient\"")
    aCheck(queueServer[9] == "SC_PNG",          tostring(queueServer[9]) .. " == \"SC_PNG\"")
    aCheck(countConnect == 1,                   countConnect .. " == 1")
    aCheck(countClosed == 0,                    countClosed .. " == 0")
    aCheck(countMessage == 0,                   countMessage .. " == 0")
    
    -- Wait for ping
    mockOs.increaseTime(1)
    
    aCheck(#queueServer == 12,                  #queueServer .. " == 12")
    aCheck(queueServer[10] == 300,              tostring(queueServer[10]) .. " == 300")
    aCheck(queueServer[11] == "modemClient",    tostring(queueServer[11]) .. " == \"modemClient\"")
    aCheck(queueServer[12] == "SC_PNG",         tostring(queueServer[12]) .. " == \"SC_PNG\"")
    aCheck(countConnect == 1,                   countConnect .. " == 1")
    aCheck(countClosed == 0,                    countClosed .. " == 0")
    aCheck(countMessage == 0,                   countMessage .. " == 0")

end

testNetworkSafeConnectionClientTimeout = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)
    local queueServer = createMessageQueue(channelSocketServer)
    
    local countConnect  = 0
    local countClosed   = 0
    local countMessage  = 0

    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
    end
    
    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeClientSocket = iSafeConnection.connect(channelSocketClient, "modemServer", onConnect, onClosed, onMessage)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(queueServer[1] == 300,           tostring(queueServer[1]) .. " == 300")
    aCheck(queueServer[2] == "modemClient", tostring(queueServer[2]) .. " == \"modemClient\"")
    aCheck(queueServer[3] == "SC_CON",      tostring(queueServer[3]) .. " == SC_CON")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Accept connection
    channelSocketServer.send("modemClient", "SC_COR", true)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Wait for timeout
    mockOs.increaseTime(5)
    
    aCheck(#queueServer == 6,               #queueServer .. " == 6")
    aCheck(queueServer[4] == 300,           tostring(queueServer[4]) .. " == 300")
    aCheck(queueServer[5] == "modemClient", tostring(queueServer[5]) .. " == \"modemClient\"")
    aCheck(queueServer[6] == "SC_PNG",      tostring(queueServer[6]) .. " == \"SC_PNG\"")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 1,                countClosed .. " == 1")
    aCheck(countMessage == 0,               countMessage .. " == 0")
end

testNetworkSafeConnectionClientTimeoutAfterPing = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)
    local queueServer = createMessageQueue(channelSocketServer)
    
    local countConnect  = 0
    local countClosed   = 0
    local countMessage  = 0

    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
    end
    
    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeClientSocket = iSafeConnection.connect(channelSocketClient, "modemServer", onConnect, onClosed, onMessage)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(queueServer[1] == 300,           tostring(queueServer[1]) .. " == 300")
    aCheck(queueServer[2] == "modemClient", tostring(queueServer[2]) .. " == \"modemClient\"")
    aCheck(queueServer[3] == "SC_CON",      tostring(queueServer[3]) .. " == SC_CON")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Accept connection
    channelSocketServer.send("modemClient", "SC_COR", true)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Wait for ping
    mockOs.increaseTime(4)
    
    aCheck(#queueServer == 6,               #queueServer .. " == 6")
    aCheck(queueServer[4] == 300,           tostring(queueServer[4]) .. " == 300")
    aCheck(queueServer[5] == "modemClient", tostring(queueServer[5]) .. " == \"modemClient\"")
    aCheck(queueServer[6] == "SC_PNG",      tostring(queueServer[6]) .. " == \"SC_PNG\"")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")
    
    -- Send Ping
    channelSocketServer.send("modemClient", "SC_PNG")
    
    -- Wait for ping
    mockOs.increaseTime(4)
    
    aCheck(#queueServer == 9,               #queueServer .. " == 9")
    aCheck(queueServer[7] == 300,           tostring(queueServer[7]) .. " == 300")
    aCheck(queueServer[8] == "modemClient", tostring(queueServer[8]) .. " == \"modemClient\"")
    aCheck(queueServer[9] == "SC_PNG",      tostring(queueServer[9]) .. " == \"SC_PNG\"")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")
    
    -- Wait for timeout
    mockOs.increaseTime(1)
    
    aCheck(#queueServer == 9,               #queueServer .. " == 9")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 1,                countClosed .. " == 1")
    aCheck(countMessage == 0,               countMessage .. " == 0")
end

testNetworkSafeConnectionClientCloseFromServer = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)
    local queueServer = createMessageQueue(channelSocketServer)
    
    local countConnect  = 0
    local countClosed   = 0
    local countMessage  = 0

    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
    end
    
    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeClientSocket = iSafeConnection.connect(channelSocketClient, "modemServer", onConnect, onClosed, onMessage)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(queueServer[1] == 300,           tostring(queueServer[1]) .. " == 300")
    aCheck(queueServer[2] == "modemClient", tostring(queueServer[2]) .. " == \"modemClient\"")
    aCheck(queueServer[3] == "SC_CON",      tostring(queueServer[3]) .. " == SC_CON")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Accept connection
    channelSocketServer.send("modemClient", "SC_COR", true)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Send close frame
    channelSocketServer.send("modemClient", "SC_CLS")
    
    aCheck(#queueServer == 6,               #queueServer .. " == 6")
    aCheck(queueServer[4] == 300,           tostring(queueServer[4]) .. " == 300")
    aCheck(queueServer[5] == "modemClient", tostring(queueServer[5]) .. " == \"modemClient\"")
    aCheck(queueServer[6] == "SC_CLS",      tostring(queueServer[6]) .. " == SC_CLS")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 1,                countClosed .. " == 1")
    aCheck(countMessage == 0,               countMessage .. " == 0")
end

testNetworkSafeConnectionClientCloseFromClient = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)
    local queueServer = createMessageQueue(channelSocketServer)
    
    local countConnect  = 0
    local countClosed   = 0
    local countMessage  = 0

    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
    end
    
    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeClientSocket = iSafeConnection.connect(channelSocketClient, "modemServer", onConnect, onClosed, onMessage)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(queueServer[1] == 300,           tostring(queueServer[1]) .. " == 300")
    aCheck(queueServer[2] == "modemClient", tostring(queueServer[2]) .. " == \"modemClient\"")
    aCheck(queueServer[3] == "SC_CON",      tostring(queueServer[3]) .. " == SC_CON")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Accept connection
    channelSocketServer.send("modemClient", "SC_COR", true)
    
    aCheck(#queueServer == 3,               #queueServer .. " == 3")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    iSafeClientSocket.close()

    aCheck(#queueServer == 6,               #queueServer .. " == 6")
    aCheck(queueServer[4] == 300,           tostring(queueServer[4]) .. " == 300")
    aCheck(queueServer[5] == "modemClient", tostring(queueServer[5]) .. " == \"modemClient\"")
    aCheck(queueServer[6] == "SC_CLS",      tostring(queueServer[6]) .. " == SC_CLS")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")
    
    -- Send close frame
    channelSocketServer.send("modemClient", "SC_CLS")
    
    aCheck(#queueServer == 6,               #queueServer .. " == 6")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countClosed == 1,                countClosed .. " == 1")
    aCheck(countMessage == 0,               countMessage .. " == 0")
end

-- iSafeConnectionAcceptor

testNetworkSafeConnectionAcceptor = function(aCheck)
    local channelSocketClient, channelSocketServer = setupChannelSockets(connectorSetupDataClient, connectorSetupDataServer)

    local queueClient = createMessageQueue(channelSocketClient)
    
    local countClosed           = 0
    local countConnect          = 0
    local countConnectorClosed  = 0
    local countMessage          = 0

    local clientConnector = nil

    local onClosed = function()
        countClosed = countClosed + 1
    end
    local onConnect = function()
        countConnect = countConnect + 1
    end
    local onConnectorClosed = function()
        countConnectorClosed = countConnectorClosed + 1
    end
    local onMessage = function(...)
        countMessage = countMessage + 1
    end

    local iOs, mockOs = osMockCreate()
    
    local iSafeConnection = safeConnectionCreate(iOs)

    local iSafeAcceptor = iSafeConnection.accept(channelSocketServer, onClosed, onConnect, onConnectorClosed, onMessage)
    
    aCheck(#queueClient == 0,               #queueClient .. " == 0")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countConnect == 0,               countConnect .. " == 0")
    aCheck(countConnectorClosed == 0,       countConnectorClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Connect client
    channelSocketClient.send("modemServer", "SC_CON")
    
    aCheck(#queueClient == 4,               #queueClient .. " == 4")
    aCheck(queueClient[1] == 300,           tostring(queueClient[1]) .. " == 300")
    aCheck(queueClient[2] == "modemServer", tostring(queueClient[2]) .. " == \"modemServer\"")
    aCheck(queueClient[3] == "SC_COR",      tostring(queueClient[3]) .. " == SC_COR")
    aCheck(queueClient[4] == true,          tostring(queueClient[4]) .. " == true")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countConnectorClosed == 0,       countConnectorClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")

    -- Connect client again
    iSafeAcceptor.close()
    
    aCheck(#queueClient == 7,               #queueClient .. " == 7")
    aCheck(queueClient[5] == 300,           tostring(queueClient[5]) .. " == 300")
    aCheck(queueClient[6] == "modemServer", tostring(queueClient[6]) .. " == \"modemServer\"")
    aCheck(queueClient[7] == "SC_CLS",      tostring(queueClient[7]) .. " == SC_CLS")
    aCheck(countClosed == 0,                countClosed .. " == 0")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countConnectorClosed == 0,       countConnectorClosed .. " == 0")
    aCheck(countMessage == 0,               countMessage .. " == 0")
    
    -- Disconnect client
    channelSocketClient.send("modemServer", "SC_CLS")
    
    aCheck(#queueClient == 7,               #queueClient .. " == 7")
    aCheck(countClosed == 1,                countClosed .. " == 1")
    aCheck(countConnect == 1,               countConnect .. " == 1")
    aCheck(countConnectorClosed == 1,       countConnectorClosed .. " == 1")
    aCheck(countMessage == 0,               countMessage .. " == 0")
end
