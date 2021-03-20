## SafeConnection
-iSafeConnection.accept(aIChannelSocket, aOnClosed, aOnConnection, aOnClosedConnection, aOnConnectorMessage) return rAccepting
-iSafeConnection.connect(aIChannelSocket, aAddress, aOnConnection, aOnClosedConnection, aOnMessage) return rISafeConnectionSocket

## SafeConnectionAcceptor
-iSafeConnectionAcceptor.close() return nil
-iSafeConnectionAcceptor.isOpen() return rOpen

## SafeConnectionConnector
-iSafeConnectionConnector.send(...) return rSent
-iSafeConnectionConnector.close() return nil
-iSafeConnectionConnector.isOpen() return rOpen