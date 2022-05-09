import Foundation

import BTPreprocessor

public struct BTHelperXPCClient {
    private static var connect: NSXPCConnection? = nil
    private static var helper: BTHelperCommProtocol?     = nil

    private static func interruptionHandler() {
        debugPrint("XPC client connection interrupted")
    }
    
    private static func invalidationHandler() {
        debugPrint("XPC client connection invalidated")
        BTHelperXPCClient.connect = nil
        BTHelperXPCClient.helper  = nil
    }

    public static func start() -> Bool {
        assert(connect == nil)
        assert(helper == nil)

        let lConnect = NSXPCConnection(
            machServiceName: BT_HELPER_NAME,
            options: .privileged
            )

        lConnect.exportedInterface = NSXPCInterface(with: BTClientCommProtocol.self)
        lConnect.exportedObject    = BTCClientComm()

        lConnect.remoteObjectInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        
        lConnect.invalidationHandler = BTHelperXPCClient.invalidationHandler
        lConnect.interruptionHandler = BTHelperXPCClient.interruptionHandler
        
        lConnect.resume()
        
        guard let lHelper = lConnect.remoteObjectProxyWithErrorHandler({ error in
            debugPrint("XPC client remote object error: ", error)
        }) as? BTHelperCommProtocol else {
            debugPrint("XPC client remote object is malfored")
            lConnect.suspend()
            lConnect.invalidate()
            return false
        }
        
        connect = lConnect
        helper  = lHelper
        
        return true
    }
    
    public static func stop() {
        guard let lConnect = BTHelperXPCClient.connect else {
            assert(helper == nil)
            return
        }
        
        assert(BTHelperXPCClient.helper != nil)

        BTHelperXPCClient.connect = nil
        BTHelperXPCClient.helper  = nil
        
        lConnect.suspend()
        lConnect.invalidate()
    }
    
    public static func queryExternalPowerEnabled() -> Void {
        BTHelperXPCClient.helper?.queryExternalPowerEnabled()
    }

    public static func disableExternalPower() -> Void {
        BTHelperXPCClient.helper?.disableExternalPower()
    }

    public static func enableExternalPower() -> Void {
        BTHelperXPCClient.helper?.enableExternalPower()
    }

    public static func chargeToMaximum() -> Void {
        BTHelperXPCClient.helper?.chargeToMaximum()
    }

    public static func chargeToFull() -> Void {
        BTHelperXPCClient.helper?.chargeToFull()
    }
}
