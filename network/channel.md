## iChannel
-iChannel.open(aPort) return rIChannelSocket
-iChannel.isOpen(aPort) return rOpen
-iChannel.close(aPort) return rClosed

## iChannelSocket
-iChannelSocket.close() return rClosed
-iChannelSocket.send(aAddress, ...) return rSent
-iChannelSocket.broadcast(aAddress, aPort, ...) return rSent
-iChannelSocket.setCallback(aCallback) return nil