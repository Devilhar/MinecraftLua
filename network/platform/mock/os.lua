
osMockCreate = function()
    local nextTimerId = 1
    local timers = {}
    local currentTime = 0

    local mockOs = {}

    mockOs.increaseTime = function(aTime)
        currentTime = currentTime + aTime

        local expiredTimers = {}

        for id, timer in pairs(timers) do
            if currentTime >= timer.time then
                table.insert(expiredTimers, id)
            end
        end

        for _, id in ipairs(expiredTimers) do
            if timers[id] then
                timers[id].callback(id)

                timers[id] = nil
            end
        end
    end

    local iOs = {}

    iOs.startTimer = function(aTimeout, aCallback)
        local timerId = nextTimerId

        timers[timerId] = {
            callback = aCallback,
            time = currentTime + aTimeout
        }
        nextTimerId = nextTimerId + 1

        return timerId
    end
    iOs.stopTimer = function(aTimerId)
        timers[aTimerId] = nil
    end
    
    return iOs, mockOs
end
