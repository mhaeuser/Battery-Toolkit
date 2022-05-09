import Foundation

public struct BatteryToolkit {
    public static func start() -> Bool {
        return BTPowerEvents.start()
    }

    public static func stop() {
        BTPowerEvents.stop()
    }

    public static func disableExternalPower() {
        BTPowerState.disableExternalPower()
    }

    public static func enableExternalPower() {
        BTPowerState.enableExternalPower()
    }

    public static func chargeToMaximum() {
        BTPowerEvents.chargeToMaximum()
    }

    public static func chargeToFull() {
        BTPowerEvents.chargeToFull()
    }
}
