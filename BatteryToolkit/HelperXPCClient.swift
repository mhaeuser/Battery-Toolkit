import Foundation

import BTPreprocessor

public struct BTHelperXPCClient {
    private static var connect: NSXPCConnection?     = nil
    private static var helper: BTHelperCommProtocol? = nil

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
            machServiceName: BT_DAEMON_NAME,
            options: .privileged
            )

        lConnect.remoteObjectInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        
        lConnect.invalidationHandler = BTHelperXPCClient.invalidationHandler
        lConnect.interruptionHandler = BTHelperXPCClient.interruptionHandler
        
        lConnect.resume()
        
        guard let lHelper = lConnect.remoteObjectProxyWithErrorHandler({ error in
            debugPrint("XPC client remote object error: \(error)")
        }) as? BTHelperCommProtocol else {
            debugPrint("XPC client remote object is malfored")
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

        lConnect.invalidate()
    }
    
    public static func queryPowerAdapterEnabled(reply: @escaping ((Bool) -> Void)) -> Void {
        BTHelperXPCClient.helper?.queryPowerAdapterEnabled(reply: reply)
    }

    public static func disablePowerAdapter() -> Void {
        BTHelperXPCClient.helper?.disablePowerAdapter()
    }

    public static func enablePowerAdapter() -> Void {
        BTHelperXPCClient.helper?.enablePowerAdapter()
    }

    public static func chargeToMaximum() -> Void {
        BTHelperXPCClient.helper?.chargeToMaximum()
    }

    public static func chargeToFull() -> Void {
        BTHelperXPCClient.helper?.chargeToFull()
    }
    
    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) -> Void {
        BTHelperXPCClient.helper?.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
    
    public static func setAdapterSleep(enabled: Bool) {
        BTHelperXPCClient.helper?.setAdapterSleep(enabled: enabled)
    }
    
    public static func removeHelperFiles() {
        BTHelperXPCClient.helper?.removeHelperFiles()
    }
}
