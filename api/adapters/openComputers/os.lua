local event = require("event")

osOpenOsCreate = function()
    local iOs = {}

    iOs.startTimer = function(aTimeout, aCallback)
        return event.timer(aTimeout, aCallback)
    end
    iOs.stopTimer = function(aTimerId)
        return event.cancel(aTimerId)
    end
    
    return iOs, mockOs
end
