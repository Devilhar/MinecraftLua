
safeConnectionCreate = function(aIOs)
    local messageTypes = {
        connect     = "SC_CON",
        connectRsp  = "SC_COR",
        close       = "SC_CLS",
        ping        = "SC_PNG",
        message     = "SC_MSG",
        messageRsp  = "SC_MSR"
    }
    local timeout = 5
    local pingInterval = 1
    local resendTime = 0.5

    local connectorCreate = function(aIsAcceptor, aIChannelSocket, aAddress, aOnConnection, aOnClosedConnection, aOnMessage)
        if not aIChannelSocket.isOpen() then
            return nil
        end

        local callbackId = nil

        local connected = false
        local closing = false
        local closed = false

        local timerIdTimeout = nil
        local timerIdClose = nil
        local timerIdPing = nil

        local sendingMessage = false
        local timerIdResend = nil
        local messageBuffer = {}

        local nextMessageId = 1
        local lastReceivedMessageId = nil

        local sendNextMessage = function()
            local messagePayload = messageBuffer[1]

            if sendingMessage or not messagePayload then
                return
            end

            local sendPayload = nil

            sendPayload = function()
                timerIdResend = aIOs.startTimer(resendTime, sendPayload)
                aIChannelSocket.send(aAddress, table.unpack(messagePayload))
            end
            
            sendingMessage = true
            sendPayload()
        end
        local sendMessage = function(aMessageType, ...)
            table.insert(messageBuffer, {aMessageType, ...})

            if sendingMessage then
                return
            end

            sendNextMessage()
        end
        local messageResponse = function()
            local messageData = messageBuffer[1]

            if not sendingMessage or not messageData then
                return
            end

            sendingMessage = false
            table.remove(messageBuffer, 1)
            if timerIdResend then
                aIOs.stopTimer(timerIdResend)

                timerIdResend = nil
            end

            sendNextMessage()
        end

        local close = function()
            if closed then
                return
            end

            if timerIdTimeout then
                aIOs.stopTimer(timerIdTimeout)
                
                timerIdTimeout = nil
            end
            if timerIdClose then
                aIOs.stopTimer(timerIdClose)
                
                timerIdClose = nil
            end
            if timerIdPing then
                aIOs.stopTimer(timerIdPing)
                
                timerIdPing = nil
            end

            connected = false
            closing = true
            closed = true

            aIChannelSocket.removeCallback(callbackId)

            aOnClosedConnection(aAddress)
        end
        local resetTimeout = function()
            if timerIdTimeout then
                aIOs.stopTimer(timerIdTimeout)
            end

            timerIdTimeout = aIOs.startTimer(timeout, close)
        end

        local sendPing = nil
        local resetPingTimer = function()
            timerIdPing = aIOs.startTimer(pingInterval, sendPing)
        end
        sendPing = function()
            if closing then
                if timerIdPing then
                    aIOs.stopTimer(timerIdPing)
                end

                timerIdPing = nil

                return
            end

            resetPingTimer()
            aIChannelSocket.send(aAddress, messageTypes.ping)
        end

        local iSafeConnectionConnector = {}

        iSafeConnectionConnector.send = function(...)
            if not iSafeConnectionConnector.isOpen() then
                return
            end

            sendMessage(messageTypes.message, nextMessageId, ...)

            nextMessageId = nextMessageId + 1
        end
        iSafeConnectionConnector.close = function()
            if not iSafeConnectionConnector.isOpen() then
                return
            end
            
            closing = true
            if not timerIdClose then
                timerIdClose = aIOs.startTimer(timeout, close)
            end
            if timerIdPing then
                aIOs.stopTimer(timerIdPing)
                
                timerIdPing = nil
            end
            sendMessage(messageTypes.close)
        end
        iSafeConnectionConnector.isOpen = function()
            return connected and not closed and aIChannelSocket.isOpen()
        end

        callbackId = aIChannelSocket.addCallback(function(aPort, aResponseAddress, ...)
            if closed or aResponseAddress ~= aAddress then
                return
            end

            local messages = {...}

            if type(messages[1]) ~= "string" then
                return
            end

            local msgType = messages[1]

            if msgType == messageTypes.connectRsp then
                resetTimeout()
                
                local connectionAccepted = messages[2]

                if connected or not connectionAccepted then
                    return
                end

                messageResponse()
                resetPingTimer()
                connected = true
                aOnConnection(aAddress, iSafeConnectionConnector)
            elseif msgType == messageTypes.close then
                sendMessage(messageTypes.close)
                close()
            elseif msgType == messageTypes.ping then
                resetTimeout()
            elseif msgType == messageTypes.message then
                resetTimeout()
                aIChannelSocket.send(aAddress, messageTypes.messageRsp)
                table.remove(messages, 1)

                local messageId = messages[1]

                if messageId == lastReceivedMessageId then
                    return
                end
    
                lastReceivedMessageId = messageId
                table.remove(messages, 1)

                aOnMessage(table.unpack(messages))
            elseif msgType == messageTypes.messageRsp then
                resetTimeout()
                messageResponse()
            end
        end)

        resetTimeout()
        if aIsAcceptor then
            resetPingTimer()
            connected = true
            aOnConnection(aAddress, iSafeConnectionConnector)
        else
            sendMessage(messageTypes.connect)
        end

        return iSafeConnectionConnector
    end

    local iSafeConnection = {}

    iSafeConnection.accept = function(aIChannelSocket, aOnClosed, aOnConnection, aOnClosedConnection, aOnConnectorMessage)
        if not aIChannelSocket.isOpen() then
            return nil
        end

        local callbackId = nil

        local closed = false
        local closing = false

        local connectors = {}
        local hasConnectors = function()
            for _, _ in pairs(connectors) do
                return true
            end

            return false
        end

        local close = function()
            closed = true

            aOnClosed()
        end

        local iSafeConnectionAcceptor = {}

        iSafeConnectionAcceptor.close = function()
            if not iSafeConnectionAcceptor.isOpen() then
                return
            end

            closing = true

            if not hasConnectors() then
                close()

                return
            end

            for _, connectors in pairs(connectors) do
                connectors.close()
            end
        end
        iSafeConnectionAcceptor.isOpen = function()
            return not closed and aIChannelSocket.isOpen()
        end

        callbackId = aIChannelSocket.addCallback(function(aPort, aResponseAddress, ...)
            if closing then
                return
            end

            local messages = {...}

            local msgType = messages[1]

            if msgType ~= messageTypes.connect then
                return
            end

            if connectors[aResponseAddress] then
                aIChannelSocket.send(aResponseAddress, messageTypes.connectRsp, true)

                return
            end

            local isAcceptor = true
            local onClosedConnection = function(aAddress)
                connectors[aAddress] = nil

                aOnClosedConnection(aAddress)

                if closing and not hasConnectors() then
                    close()
                end
            end

            local iSafeConnectionConnector = connectorCreate(isAcceptor, aIChannelSocket, aResponseAddress, aOnConnection, onClosedConnection, aOnConnectorMessage)
            aIChannelSocket.send(aResponseAddress, messageTypes.connectRsp, true)
            
            connectors[aResponseAddress] = iSafeConnectionConnector
        end)

        return iSafeConnectionAcceptor
    end
    iSafeConnection.connect = function(aIChannelSocket, aAddress, aOnConnection, aOnClosedConnection, aOnMessage)
        local isAcceptor = false

        return connectorCreate(isAcceptor, aIChannelSocket, aAddress, aOnConnection, aOnClosedConnection, aOnMessage)
    end

    return iSafeConnection
end
