
networkMockCreate = function()
    local modems = {}

    local mockNetwork = {}

    mockNetwork.modemCreate = function(aNetAddress)
        local ports = {}
        local callback = nil

        local mockModem = {}

        local pushModemMessage = function(aPort, ...)
            if not callback or not ports[aPort] then
                return
            end

            callback(aPort, ...)
        end

        local sendMessage = function(aAddress, aPort, ...)
            if aAddress then
                if not modems[aAddress] then
                    return
                end
        
                modems[aAddress].pushModemMessage(aPort, aNetAddress, ...)
            else
                for address, modem in pairs(modems) do
                    if address ~= aNetAddress then
                        modem.pushModemMessage(aPort, aNetAddress, ...)
                    end
                end
            end
        end
    
        local iModem = {}

        iModem.open = function(aPort)
            if ports[aPort] then
                return false
            end
            
            ports[aPort] = true

            return true
        end
        iModem.isOpen = function(aPort)
            return ports[aPort] == true
        end
        iModem.close = function(aPort)
            if not ports[aPort] then
                return false
            end
            
            ports[aPort] = nil

            return true
        end
        iModem.send = function(aAddress, aPort, ...)
            if not ports[aPort] then
                return false
            end

            sendMessage(aAddress, aPort, ...)

            return true
        end
        iModem.broadcast = function(aPort, ...)
            if not ports[aPort] then
                return false
            end

            sendMessage(nil, aPort, ...)

            return true
        end
        iModem.setCallback = function(aCallback)
            callback = aCallback
        end

        modems[aNetAddress] = {
            iModem = iModem,
            pushModemMessage = pushModemMessage
        }

        return iModem, mockModem
    end

    return mockNetwork
end
