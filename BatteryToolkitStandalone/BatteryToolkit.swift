import Foundation

internal struct BTDaemonManagement {

}

internal struct BatteryToolkit {
    internal static func startDaemon(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        let result = BTPowerEvents.start()
        reply(result ? BTDaemonManagement.Status.enabled : BTDaemonManagement.Status.notRegistered)
    }

    internal static func approveDaemon() {

    }

    internal static func stop() {
        BTPowerEvents.stop()
    }

    internal static func disablePowerAdapter() {
        BTPowerState.disablePowerAdapter()
    }

    internal static func enablePowerAdapter() {
        BTPowerState.enablePowerAdapter()
    }

    internal static func chargeToMaximum() {
        BTPowerEvents.chargeToMaximum()
    }

    internal static func chargeToFull() {
        BTPowerEvents.chargeToFull()
    }
    
    internal static func unregisterDaemon(reply: @escaping ((Bool) -> Void)) {
        
    }
}
