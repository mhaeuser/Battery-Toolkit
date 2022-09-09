import Foundation
import os.log
import BTPreprocessor

public struct BTHelperXPCClient {
    private static var connect: NSXPCConnection?     = nil
    private static var helper: BTHelperCommProtocol? = nil

    private static func interruptionHandler() {
        os_log("XPC client connection interrupted")
    }
    
    private static func invalidationHandler() {
        os_log("XPC client connection invalidated")
        BTHelperXPCClient.connect = nil
        BTHelperXPCClient.helper  = nil
    }

    public static func connectDaemon() {
        if BTHelperXPCClient.connect != nil {
            assert(BTHelperXPCClient.helper != nil)
            return
        }
        
        assert(BTHelperXPCClient.helper == nil)

        let lConnect = NSXPCConnection(
            machServiceName: BT_DAEMON_NAME,
            options: .privileged
            )

        lConnect.remoteObjectInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        
        lConnect.invalidationHandler = BTHelperXPCClient.invalidationHandler
        lConnect.interruptionHandler = BTHelperXPCClient.interruptionHandler
        
        lConnect.resume()
        
        guard let lHelper = lConnect.remoteObjectProxyWithErrorHandler({ error in
            os_log("XPC client remote object error: \(error)")
        }) as? BTHelperCommProtocol else {
            os_log("XPC client remote object is malfored")
            lConnect.invalidate()
            return
        }
        
        os_log("XPC client connected")
        
        connect = lConnect
        helper  = lHelper
    }
    
    public static func stop() {
        guard let lConnect = BTHelperXPCClient.connect else {
            assert(BTHelperXPCClient.helper == nil)
            return
        }
        
        assert(BTHelperXPCClient.helper != nil)

        BTHelperXPCClient.connect = nil
        BTHelperXPCClient.helper  = nil

        lConnect.invalidate()
    }
    
    public static func queryPowerAdapterEnabled(reply: @escaping ((Bool) -> Void)) -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.queryPowerAdapterEnabled(reply: reply)
    }

    public static func disablePowerAdapter() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.disablePowerAdapter()
    }

    public static func enablePowerAdapter() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.enablePowerAdapter()
    }

    public static func chargeToMaximum() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.chargeToMaximum()
    }

    public static func chargeToFull() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.chargeToFull()
    }
    
    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
    
    public static func setAdapterSleep(enabled: Bool) {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.setAdapterSleep(enabled: enabled)
    }
    
    public static func removeHelperFiles() {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.removeHelperFiles()
    }
}
