import Foundation

import BTPreprocessor

private final class BTHelperXPCDelegate: NSObject, NSXPCListenerDelegate {
    private static func isValidClient(forConnection connection: NSXPCConnection) -> OSStatus {
        var token = connection.auditToken;
        let tokenData = Data(
            bytes: &token,
            count: MemoryLayout.size(ofValue: token)
            )
        let attributes = [kSecGuestAttributeAudit: tokenData]

        let flags: SecCSFlags = []
        var uCode: SecCode?   = nil
        let codeStatus = SecCodeCopyGuestWithAttributes(
            nil,
            attributes as CFDictionary,
            flags,
            &uCode
            )
        if codeStatus != errSecSuccess {
            return codeStatus
        }
        
        assert(uCode != nil);
        let code = uCode!

        let entitlements = "identifier \"" + BT_APP_NAME +
            "\" and anchor apple generic and certificate leaf[subject.CN] = \"" +
            BT_CODE_SIGN_CN +
            "\" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */"
        var requirement: SecRequirement? = nil
        
        let reqStatus = SecRequirementCreateWithString(
            entitlements as CFString,
            flags,
            &requirement
            )
        if reqStatus != errSecSuccess {
            return reqStatus
        }
        
        assert(requirement != nil);
        
        return SecCodeCheckValidity(code, flags, requirement)
    }
    
    fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        if (BTHelperXPCDelegate.isValidClient(forConnection: newConnection) != errSecSuccess) {
            NSLog("XPC server connection by invalid client")
            return false
        }

        return BTHelperXPCServer.accept(newConnection: newConnection)
    }
}

public struct BTHelperXPCServer {
    private static var listener: NSXPCListener? = nil

    private static var connect: NSXPCConnection?     = nil
    private static var client: BTClientCommProtocol? = nil
    
    private static let delegate: NSXPCListenerDelegate = BTHelperXPCDelegate()
    
    public static func start() -> Bool {
        assert(listener == nil)

        let lListener      = NSXPCListener(machServiceName: BT_HELPER_NAME)
        lListener.delegate = delegate
        listener           = lListener
        lListener.resume()
        
        return true
    }
    
    public static func stop() {
        guard let lListener = listener else {
            return
        }
        
        listener = nil
        
        lListener.suspend()
        lListener.invalidate()
        
        guard let lConnect = connect else {
            return
        }
        
        assert(client != nil)

        connect = nil
        client  = nil
        
        lConnect.suspend()
        lConnect.invalidate()
    }
    
    private static func interruptionHandler() {
        NSLog("XPC server connection interrupted")
    }
    
    private static func invalidationHandler() {
        NSLog("XPC server connection invalidated")
    }
    
    fileprivate static func accept(newConnection: NSXPCConnection) -> Bool {
        if (connect != nil) {
            NSLog("XPC server ignored due to existing connection")
            assert(client != nil)
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        newConnection.exportedObject    = BTHelperComm()
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: BTClientCommProtocol.self)
        
        newConnection.interruptionHandler = interruptionHandler
        newConnection.invalidationHandler = invalidationHandler
        
        newConnection.resume()
        
        guard let lClient = newConnection.remoteObjectProxy as? BTClientCommProtocol else {
            NSLog("XPC server remote object is malfored")
            newConnection.suspend()
            newConnection.invalidate()
            return false
        }
        
        connect = newConnection
        client  = lClient
        
        return true
    }
    
    public static func submitExternalPowerEnabled(enabled: Bool) -> Void {
        client?.submitExternalPowerEnabled(enabled: enabled)
    }
}
