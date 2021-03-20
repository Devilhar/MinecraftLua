## SafeConnection
-iSafeConnection.accept(iChannelSocket, aOnConnection, aOnClosedConnection, aOnMessage) return rAccepting
-iSafeConnection.connect(iChannelSocket, aAddress, aOnConnection, aOnClosedConnection, aOnMessage) return rISafeConnectionSocket

## SafeConnectionSocket
-iSafeConnectionSocket.send(...) return rSent
-iSafeConnectionSocket.close() return nil
-iSafeConnectionSocket.isOpen() return rOpen