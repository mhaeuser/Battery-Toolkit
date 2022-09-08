import Foundation

public struct BatteryToolkit {
    public static func start() -> Bool {
        return BTPowerEvents.start()
    }

    public static func stop() {
        BTPowerEvents.stop()
    }

    public static func disablePowerAdapter() {
        BTPowerState.disablePowerAdapter()
    }

    public static func enablePowerAdapter() {
        BTPowerState.enablePowerAdapter()
    }

    public static func chargeToMaximum() {
        BTPowerEvents.chargeToMaximum()
    }

    public static func chargeToFull() {
        BTPowerEvents.chargeToFull()
    }
    
    public static func unregisterDaemon(reply: @escaping ((Bool) -> Void)) {
        
    }
}
