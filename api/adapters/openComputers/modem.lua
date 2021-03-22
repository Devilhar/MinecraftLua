local event = require("event")

modemOpenOsCreate = function(aModem)
    local callback = nil
    local iModem = {}

    iModem.open = function(aPort)
        return aModem.open(aPort)
    end
    iModem.isOpen = function(aPort)
        return aModem.isOpen(aPort)
    end
    iModem.close = function(aPort)
        return aModem.close(aPort)
    end
    iModem.send = function(aAddress, aPort, ...)
        return aModem.send(aAddress, aPort, ...)
    end
    iModem.broadcast = function(aPort, ...)
        return aModem.broadcast(aPort, ...)
    end
    iModem.setCallback = function(aCallback)
        if callback then
            event.ignore("modem_message", callback)
                    
            callback = nil
        end

        if aCallback thens
            callback = function(aAddressLocal, aAddressRemote, aPort, _, ...)
                if aAddressLocal ~= aModem.address then
                    return
                end

                aCallback(aPort, aAddressRemote, ...)
            end

            event.listen("modem_message", callback)
        end
    end

    return iModem
end
