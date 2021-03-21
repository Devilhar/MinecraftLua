## iChannel
-iChannel.open(aPort) return rIChannelSocket
-iChannel.isOpen(aPort) return rOpen
-iChannel.close(aPort) return rClosed

## iChannelSocket
-iChannelSocket.isOpen() return rOpen
-iChannelSocket.close() return rClosed
-iChannelSocket.send(aAddress, ...) return rSent
-iChannelSocket.broadcast(aAddress, aPort, ...) return rSent
-iChannelSocket.addCallback(aCallback) return rCallbackId
-iChannelSocket.removeCallback(aCallbackId) return rRemoved