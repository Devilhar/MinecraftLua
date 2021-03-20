
channelCreate = function(aIModem)

    local iChannel = {}
    local channelMap = {}

    aIModem.setCallback(function(aPort, aResponseAddress, ...)
        if not channelMap[aPort] or not channelMap[aPort].callback then
            return
        end

        channelMap[aPort].callback(aPort, aResponseAddress, ...)
    end)

    iChannel.open = function(aPort)

        if channelMap[aPort] or not aIModem.open(aPort) then
            return nil
        end

        local iChannelSocket = {}

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
        iChannelSocket.setCallback = function(aCallback)
            channelMap[aPort].callback = aCallback
        end

        channelMap[aPort] = {
            interface = iChannelSocket,
            callback = nil
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
