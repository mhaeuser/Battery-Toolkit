import Foundation
import IOPMPrivate

public final class BTHelperComm: NSObject, BTHelperCommProtocol {
    func queryExternalPowerEnabled() -> Void {
        let enabled = SMCPowerKit.isExternalPowerEnabled()
        BTHelperXPCServer.submitExternalPowerEnabled(enabled: enabled)
    }
    
    func enableExternalPower() -> Void {
        BTPowerState.enableExternalPower()
    }
    
    func disableExternalPower() -> Void {
        BTPowerState.disableExternalPower()
    }
    
    func chargeToMaximum() -> Void {
        BTPowerEvents.chargeToMaximum()
    }

    func chargeToFull() -> Void {
        BTPowerEvents.chargeToFull()
    }
    
    func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        BTPreferences.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
}
