import Foundation

private final class BTServiceXPCDelegate: NSObject, NSXPCListenerDelegate {
    fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        return BTServiceXPCServer.acceptClient(newConnection: newConnection)
    }
}

public struct BTServiceXPCServer {
    private static let delegate = BTServiceXPCDelegate()
    private static let listener = NSXPCListener.service()

    fileprivate static func acceptClient(newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: BTServiceCommProtocol.self)
        newConnection.exportedObject    = BTServiceComm()
        
        newConnection.resume()
        
        return true
    }
    
    public static func start() {
        listener.delegate = delegate
        listener.resume()
    }
}
