
require("api/io/channel")
require("api/io/safeConnection")

require("api/adapters/mock/modem")
require("api/adapters/mock/os")

require("tests/io/ioCommon")

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

-- iSafeConnectionConnector

local testConnectorMessage = function(aCheck)
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
    
    aCheck(#queueServer == 11,                              #queueServer .. " == 11")
    aCheck(queueServer[9] == 300,                           tostring(queueServer[9]) .. " == 300")
    aCheck(queueServer[10] == "modemClient",                tostring(queueServer[10]) .. " == \"modemClient\"")
    aCheck(queueServer[11] == "SC_MSR",                     tostring(queueServer[11]) .. " == \"SC_MSR\"")
    aCheck(countConnect == 1,                               countConnect .. " == 1")
    aCheck(countClosed == 0,                                countClosed .. " == 0")
    aCheck(countMessage == 1,                               countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 3,                     #messagePayloadsClient .. " == 3")
    aCheck(messagePayloadsClient[1] == "modemServer",       tostring(messagePayloadsClient[1]) .. " == \"modemServer\"")
    aCheck(messagePayloadsClient[2] == iSafeClientSocket,   tostring(messagePayloadsClient[2]) .. " == " .. tostring(iSafeClientSocket))
    aCheck(messagePayloadsClient[3] == "Hello World",       tostring(messagePayloadsClient[3]) .. " == \"Hello World\"")
    
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
    aCheck(#messagePayloadsClient == 3,                 #messagePayloadsClient .. " == 3")
    
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
    aCheck(#messagePayloadsClient == 3,                 #messagePayloadsClient .. " == 3")
    
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
    aCheck(#messagePayloadsClient == 3,                 #messagePayloadsClient .. " == 3")
    
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
    aCheck(#messagePayloadsClient == 3,                 #messagePayloadsClient .. " == 3")
    
    -- Send message response
    channelSocketServer.send("modemClient", "SC_MSR")
    
    aCheck(#queueServer == 34,                          #queueServer .. " == 34")
    aCheck(countConnect == 1,                           countConnect .. " == 1")
    aCheck(countClosed == 0,                            countClosed .. " == 0")
    aCheck(countMessage == 1,                           countMessage .. " == 1")
    aCheck(#messagePayloadsClient == 3,                 #messagePayloadsClient .. " == 3")
end

local testConnectorPing = function(aCheck)
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

local testConnectorTimeout = function(aCheck)
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

local testConnectorTimeoutAfterPing = function(aCheck)
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

local testConnectorCloseFromServer = function(aCheck)
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

local testConnectorCloseFromClient = function(aCheck)
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

local testAcceptor = function(aCheck)
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

-- iSafeConnection Connection

local testConnection = function(aCheck)
    
    local countServerClosed             = 0
    local countServerConnect            = 0
    local countServerConnectorClosed    = 0
    local countServerMessage            = 0
    local countClientAConnect           = 0
    local countClientAClosed            = 0
    local countClientAMessage           = 0
    local countClientBConnect           = 0
    local countClientBClosed            = 0
    local countClientBMessage           = 0

    local serverAcceptor    = nil
    local serverConnectorA  = nil
    local serverConnectorB  = nil
    local clientAConnector  = nil
    local clientBConnector  = nil

    local serverMessageQueue    = {}
    local clientAMessageQueue   = {}
    local clientBMessageQueue   = {}

    local onServerClosed = function()
        countServerClosed = countServerClosed + 1
    end
    local onServerConnect = function(aAddress, aConnector)
        countServerConnect = countServerConnect + 1
        if aAddress == "modemClientA" then
            serverConnectorA = aConnector
        elseif aAddress == "modemClientB" then
            serverConnectorB = aConnector
        end
    end
    local onServerConnectorClosed = function()
        countServerConnectorClosed = countServerConnectorClosed + 1
    end
    local onServerMessage = function(...)
        countServerMessage = countServerMessage + 1
        for _, message in ipairs({...}) do
            table.insert(serverMessageQueue, message)
        end
    end
    local onClientAConnect = function()
        countClientAConnect = countClientAConnect + 1
    end
    local onClientAClosed = function()
        countClientAClosed = countClientAClosed + 1
    end
    local onClientAMessage = function(...)
        countClientAMessage = countClientAMessage + 1
        for _, message in ipairs({...}) do
            table.insert(clientAMessageQueue, message)
        end
    end
    local onClientBConnect = function()
        countClientBConnect = countClientBConnect + 1
    end
    local onClientBClosed = function()
        countClientBClosed = countClientBClosed + 1
    end
    local onClientBMessage = function(...)
        countClientBMessage = countClientBMessage + 1
        for _, message in ipairs({...}) do
            table.insert(clientBMessageQueue, message)
        end
    end

    local connectorDataServer = {
        address = "modemServer",
        port = 400
    }
    local connectorDataClientA = {
        address = "modemClientA",
        port = 400
    }
    local connectorDataClientB = {
        address = "modemClientB",
        port = 400
    }

    local iOs, mockOs = osMockCreate()
    
    local serverChannelSocket, clientAChannelSocket, clientBChannelSocket = setupChannelSockets(connectorDataServer, connectorDataClientA, connectorDataClientB)
    local iSafeConnection = safeConnectionCreate(iOs)

    serverAcceptor = iSafeConnection.accept(serverChannelSocket, onServerClosed, onServerConnect, onServerConnectorClosed, onServerMessage)
    
    aCheck(serverAcceptor.isOpen(),             tostring(serverAcceptor.isOpen()))
    aCheck(not serverConnectorA,                "not " .. tostring(serverConnectorA))
    aCheck(not serverConnectorB,                "not " .. tostring(serverConnectorB))
    aCheck(not clientAConnector,                "not " .. tostring(clientAConnector))
    aCheck(not clientBConnector,                "not " .. tostring(clientBConnector))
    aCheck(#serverMessageQueue          == 0,   #serverMessageQueue         .. " == 0")
    aCheck(#clientAMessageQueue         == 0,   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 0,   countServerConnect          .. " == 0")
    aCheck(countServerConnectorClosed   == 0,   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 0,   countServerMessage          .. " == 0")
    aCheck(countClientAConnect          == 0,   countClientAConnect         .. " == 0")
    aCheck(countClientAClosed           == 0,   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 0,   countClientBConnect         .. " == 0")
    aCheck(countClientBClosed           == 0,   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,   countClientBMessage         .. " == 0")

    clientAConnector = iSafeConnection.connect(clientAChannelSocket, "modemServer", onClientAConnect, onClientAClosed, onClientAMessage)

    aCheck(serverAcceptor.isOpen(),             tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),           tostring(serverConnectorA.isOpen()))
    aCheck(not serverConnectorB,                "not " .. tostring(serverConnectorB))
    aCheck(clientAConnector.isOpen(),           tostring(clientAConnector.isOpen()))
    aCheck(not clientBConnector,                "not " .. tostring(clientBConnector))
    aCheck(#serverMessageQueue          == 0,   #serverMessageQueue         .. " == 0")
    aCheck(#clientAMessageQueue         == 0,   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 1,   countServerConnect          .. " == 1")
    aCheck(countServerConnectorClosed   == 0,   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 0,   countServerMessage          .. " == 0")
    aCheck(countClientAConnect          == 1,   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 0,   countClientBConnect         .. " == 0")
    aCheck(countClientBClosed           == 0,   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,   countClientBMessage         .. " == 0")

    clientBConnector = iSafeConnection.connect(clientBChannelSocket, "modemServer", onClientBConnect, onClientBClosed, onClientBMessage)

    aCheck(serverAcceptor.isOpen(),     tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),   tostring(serverConnectorA.isOpen()))
    aCheck(serverConnectorB.isOpen(),   tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),   tostring(clientAConnector.isOpen()))
    aCheck(clientBConnector.isOpen(),   tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 0,   #serverMessageQueue         .. " == 0")
    aCheck(#clientAMessageQueue         == 0,   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,   countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 0,   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 0,   countServerMessage          .. " == 0")
    aCheck(countClientAConnect          == 1,   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,   countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 0,   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,   countClientBMessage         .. " == 0")

    mockOs.increaseTime(1)
    
    aCheck(serverAcceptor.isOpen(),     tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),   tostring(serverConnectorA.isOpen()))
    aCheck(serverConnectorB.isOpen(),   tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),   tostring(clientAConnector.isOpen()))
    aCheck(clientBConnector.isOpen(),   tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 0,   #serverMessageQueue         .. " == 0")
    aCheck(#clientAMessageQueue         == 0,   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,   countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 0,   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 0,   countServerMessage          .. " == 0")
    aCheck(countClientAConnect          == 1,   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,   countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 0,   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,   countClientBMessage         .. " == 0")

    mockOs.increaseTime(1)
    
    aCheck(serverAcceptor.isOpen(),     tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),   tostring(serverConnectorA.isOpen()))
    aCheck(serverConnectorB.isOpen(),   tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),   tostring(clientAConnector.isOpen()))
    aCheck(clientBConnector.isOpen(),   tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 0,   #serverMessageQueue         .. " == 0")
    aCheck(#clientAMessageQueue         == 0,   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,   countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 0,   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 0,   countServerMessage          .. " == 0")
    aCheck(countClientAConnect          == 1,   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,   countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 0,   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,   countClientBMessage         .. " == 0")
    
    mockOs.increaseTime(4)
    
    aCheck(serverAcceptor.isOpen(),     tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),   tostring(serverConnectorA.isOpen()))
    aCheck(serverConnectorB.isOpen(),   tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),   tostring(clientAConnector.isOpen()))
    aCheck(clientBConnector.isOpen(),   tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 0,   #serverMessageQueue         .. " == 0")
    aCheck(#clientAMessageQueue         == 0,   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,   countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 0,   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 0,   countServerMessage          .. " == 0")
    aCheck(countClientAConnect          == 1,   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,   countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 0,   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,   countClientBMessage         .. " == 0")

    clientAConnector.send("Hello")
    
    aCheck(serverAcceptor.isOpen(),                             tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),                           tostring(serverConnectorA.isOpen()))
    aCheck(serverConnectorB.isOpen(),                           tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),                           tostring(clientAConnector.isOpen()))
    aCheck(clientBConnector.isOpen(),                           tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 3,                   #serverMessageQueue         .. " == 3")
    aCheck(#clientAMessageQueue         == 0,                   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 0,                   #clientBMessageQueue        .. " == 0")
    aCheck(countServerClosed            == 0,                   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,                   countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 0,                   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 1,                   countServerMessage          .. " == 1")
    aCheck(countClientAConnect          == 1,                   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,                   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,                   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,                   countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 0,                   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 0,                   countClientBMessage         .. " == 0")
    aCheck(serverMessageQueue[1]        == "modemClientA",      tostring(serverMessageQueue[1]) .. " == \"modemClientA\"")
    aCheck(serverMessageQueue[2]        == serverConnectorA,    tostring(serverMessageQueue[2]) .. " == " .. tostring(serverConnectorA))
    aCheck(serverMessageQueue[3]        == "Hello",             tostring(serverMessageQueue[3]) .. " == \"Hello\"")

    serverConnectorB.send("World")
    
    aCheck(serverAcceptor.isOpen(),                             tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),                           tostring(serverConnectorA.isOpen()))
    aCheck(serverConnectorB.isOpen(),                           tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),                           tostring(clientAConnector.isOpen()))
    aCheck(clientBConnector.isOpen(),                           tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 3,                   #serverMessageQueue         .. " == 3")
    aCheck(#clientAMessageQueue         == 0,                   #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 3,                   #clientBMessageQueue        .. " == 3")
    aCheck(countServerClosed            == 0,                   countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,                   countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 0,                   countServerConnectorClosed  .. " == 0")
    aCheck(countServerMessage           == 1,                   countServerMessage          .. " == 1")
    aCheck(countClientAConnect          == 1,                   countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,                   countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,                   countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,                   countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 0,                   countClientBClosed          .. " == 0")
    aCheck(countClientBMessage          == 1,                   countClientBMessage         .. " == 1")
    aCheck(clientBMessageQueue[1]       == "modemServer",       tostring(clientBMessageQueue[1]) .. " == \"modemServer\"")
    aCheck(clientBMessageQueue[2]       == clientBConnector,    tostring(clientBMessageQueue[2]) .. " == " .. tostring(clientBConnector))
    aCheck(clientBMessageQueue[3]       == "World",             tostring(clientBMessageQueue[3]) .. " == \"World\"")

    clientBConnector.close()
    
    aCheck(serverAcceptor.isOpen(),                     tostring(serverAcceptor.isOpen()))
    aCheck(serverConnectorA.isOpen(),                   tostring(serverConnectorA.isOpen()))
    aCheck(not serverConnectorB.isOpen(),               "not " .. tostring(serverConnectorB.isOpen()))
    aCheck(clientAConnector.isOpen(),                   tostring(clientAConnector.isOpen()))
    aCheck(not clientBConnector.isOpen(),               "not " .. tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 3,           #serverMessageQueue         .. " == 3")
    aCheck(#clientAMessageQueue         == 0,           #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 3,           #clientBMessageQueue        .. " == 3")
    aCheck(countServerClosed            == 0,           countServerClosed           .. " == 0")
    aCheck(countServerConnect           == 2,           countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 1,           countServerConnectorClosed  .. " == 1")
    aCheck(countServerMessage           == 1,           countServerMessage          .. " == 1")
    aCheck(countClientAConnect          == 1,           countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 0,           countClientAClosed          .. " == 0")
    aCheck(countClientAMessage          == 0,           countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,           countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 1,           countClientBClosed          .. " == 1")
    aCheck(countClientBMessage          == 1,           countClientBMessage         .. " == 1")

    serverAcceptor.close()
    
    aCheck(not serverAcceptor.isOpen(),                 "not " .. tostring(serverAcceptor.isOpen()))
    aCheck(not serverConnectorA.isOpen(),               "not " .. tostring(serverConnectorA.isOpen()))
    aCheck(not serverConnectorB.isOpen(),               "not " .. tostring(serverConnectorB.isOpen()))
    aCheck(not clientAConnector.isOpen(),               "not " .. tostring(clientAConnector.isOpen()))
    aCheck(not clientBConnector.isOpen(),               "not " .. tostring(clientBConnector.isOpen()))
    aCheck(#serverMessageQueue          == 3,           #serverMessageQueue         .. " == 3")
    aCheck(#clientAMessageQueue         == 0,           #clientAMessageQueue        .. " == 0")
    aCheck(#clientBMessageQueue         == 3,           #clientBMessageQueue        .. " == 3")
    aCheck(countServerClosed            == 1,           countServerClosed           .. " == 1")
    aCheck(countServerConnect           == 2,           countServerConnect          .. " == 2")
    aCheck(countServerConnectorClosed   == 2,           countServerConnectorClosed  .. " == 2")
    aCheck(countServerMessage           == 1,           countServerMessage          .. " == 1")
    aCheck(countClientAConnect          == 1,           countClientAConnect         .. " == 1")
    aCheck(countClientAClosed           == 1,           countClientAClosed          .. " == 1")
    aCheck(countClientAMessage          == 0,           countClientAMessage         .. " == 0")
    aCheck(countClientBConnect          == 1,           countClientBConnect         .. " == 1")
    aCheck(countClientBClosed           == 1,           countClientBClosed          .. " == 1")
    aCheck(countClientBMessage          == 1,           countClientBMessage         .. " == 1")
end

testsSafeConnection = {
    name = "SafeConnection",
    tests = {
        {
            name = "ConnectorMessage",
            test = testConnectorMessage
        },
        {
            name = "ConnectorPing",
            test = testConnectorPing
        },
        {
            name = "ConnectorTimeout",
            test = testConnectorTimeout
        },
        {
            name = "ConnectorTimeoutAfterPing",
            test = testConnectorTimeoutAfterPing
        },
        {
            name = "ConnectorCloseFromServer",
            test = testConnectorCloseFromServer
        },
        {
            name = "ConnectorCloseFromClient",
            test = testConnectorCloseFromClient
        },
        {
            name = "Acceptor",
            test = testAcceptor
        },
        {
            name = "Connection",
            test = testConnection
        }
    }
}
