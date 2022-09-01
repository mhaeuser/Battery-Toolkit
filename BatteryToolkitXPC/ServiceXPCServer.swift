import Foundation

private final class BTServiceXPCDelegate: NSObject, NSXPCListenerDelegate {
    fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        return BTServiceXPCServer.acceptClient(newConnection: newConnection)
    }
}

public struct BTServiceXPCServer {
    private static var app: BTAppCommProtocol? = nil
    
    private static let delegate = BTServiceXPCDelegate()
    private static let listener = NSXPCListener.service()

    fileprivate static func acceptClient(newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: BTServiceCommProtocol.self)
        newConnection.exportedObject    = BTServiceComm()
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: BTAppCommProtocol.self)
        
        newConnection.resume()
        
        guard let lApp = newConnection.remoteObjectProxy as? BTAppCommProtocol else {
            debugPrint("XPC server remote object is malfored")
            newConnection.suspend()
            newConnection.invalidate()
            return false
        }

        app = lApp
        
        return true
    }

    public static func submitInstallHelper(success: Bool) {
        app?.submitInstallHelper(success: success)
    }
    
    public static func start() {
        listener.delegate = delegate
        listener.resume()
    }
}
