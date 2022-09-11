import Foundation
import BTPreprocessor

internal struct BatteryToolkit {
    internal static func startDaemon(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        BTDaemonManagement.startDaemon(reply: reply)
    }
    
    internal static func stop() {
        BTHelperXPCClient.stop()
    }
    
    internal static func disablePowerAdapter() {
        BTHelperXPCClient.disablePowerAdapter()
    }

    internal static func enablePowerAdapter() {
        BTHelperXPCClient.enablePowerAdapter()
    }

    internal static func chargeToMaximum() {
        BTHelperXPCClient.chargeToMaximum()
    }

    internal static func chargeToFull() {
        BTHelperXPCClient.chargeToFull()
    }

    internal static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        BTHelperXPCClient.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
    
    internal static func setAdapterSleep(enabled: Bool) {
        BTHelperXPCClient.setAdapterSleep(enabled: enabled)
    }
    
    internal static func unregisterDaemon(reply: @escaping ((Bool) -> Void)) {
        BTDaemonManagement.unregisterDaemon(reply: reply)
    }
}
