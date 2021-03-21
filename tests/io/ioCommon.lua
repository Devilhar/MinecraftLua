
createMessageQueue = function(aIChannel)
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
