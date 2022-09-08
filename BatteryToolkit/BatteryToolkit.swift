import Foundation
import BTPreprocessor

public struct BatteryToolkit {
    public static func startXpcClient() -> Bool {
        let result = BTHelperXPCClient.start()
        
        debugPrint("XPC client start: \(result)")
        
        return result
    }
    
    public static func startDaemon(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        BTDaemonManagement.startDaemon(reply: reply)
    }
    
    public static func stop() {
        BTHelperXPCClient.stop()
    }
    
    public static func disablePowerAdapter() {
        BTHelperXPCClient.disablePowerAdapter()
    }

    public static func enablePowerAdapter() {
        BTHelperXPCClient.enablePowerAdapter()
    }

    public static func chargeToMaximum() {
        BTHelperXPCClient.chargeToMaximum()
    }

    public static func chargeToFull() {
        BTHelperXPCClient.chargeToFull()
    }

    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        BTHelperXPCClient.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
    
    public static func setAdapterSleep(enabled: Bool) {
        BTHelperXPCClient.setAdapterSleep(enabled: enabled)
    }
    
    public static func unregisterDaemon(reply: @escaping ((Bool) -> Void)) {
        BTDaemonManagement.unregisterDaemon(reply: reply)
    }
}
