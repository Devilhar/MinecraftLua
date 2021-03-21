
channelCreate = function(aIModem)

    local iChannel = {}
    local channelMap = {}

    aIModem.setCallback(function(aPort, aResponseAddress, ...)
        if not channelMap[aPort] then
            return
        end

        local callbacks = {}

        for _, callback in pairs(channelMap[aPort].callbacks) do
            table.insert(callbacks, callback)
        end

        for _, callback in ipairs(callbacks) do
            callback(aPort, aResponseAddress, ...)
        end
    end)

    iChannel.open = function(aPort)

        if channelMap[aPort] or not aIModem.open(aPort) then
            return nil
        end

        local iChannelSocket = {}

        iChannelSocket.isOpen = function()
            return aIModem.isOpen(aPort) and channelMap[aPort]
        end
        iChannelSocket.close = function()
            channelMap[aPort] = nil

            return aIModem.close(aPort)
        end
        iChannelSocket.send = function(aAddress, ...)
            if not aIModem.isOpen(aPort) then
                return false
            end

            return aIModem.send(aAddress, aPort, ...)
        end
        iChannelSocket.broadcast = function(...)
            if not aIModem.isOpen(aPort) then
                return false
            end

            return aIModem.broadcast(aPort, ...)
        end
        iChannelSocket.addCallback = function(aCallback)
            local callbackId = {}

            channelMap[aPort].callbacks[callbackId] = aCallback

            return callbackId
        end
        iChannelSocket.removeCallback = function(aCallbackId)
            if not channelMap[aPort].callbacks[aCallbackId] then
                return false
            end

            channelMap[aPort].callbacks[aCallbackId] = nil

            return true
        end

        channelMap[aPort] = {
            interface = iChannelSocket,
            callbacks = {}
        }

        return iChannelSocket
    end

    iChannel.isOpen = function(aPort)
        return aIModem.isOpen(aPort);
    end

    iChannel.close = function(aPort)
        if not channelMap[aPort] then
            return false
        end

        return channelMap[aPort].interface.close();
    end

    return iChannel
end
