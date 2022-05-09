import Foundation

@objc protocol BTHelperCommProtocol {
    func queryExternalPowerEnabled() -> Void
    func enableExternalPower() -> Void
    func disableExternalPower() -> Void
    func chargeToMaximum() -> Void
    func chargeToFull() -> Void
}
