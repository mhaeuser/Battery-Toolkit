import Foundation

internal struct BatteryToolkit {
    internal static func start() -> Bool {
        return BTPowerEvents.start()
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
