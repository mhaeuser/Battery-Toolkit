import Foundation

@objc protocol BTHelperCommProtocol {
    func queryPowerAdapterEnabled() -> Void
    func enablePowerAdapter() -> Void
    func disablePowerAdapter() -> Void
    func chargeToMaximum() -> Void
    func chargeToFull() -> Void
    func setChargeLimits(minCharge: UInt8, maxCharge: UInt8)
}
