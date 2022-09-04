import Foundation
import IOPMPrivate

public final class BTHelperComm: NSObject, BTHelperCommProtocol {
    func queryPowerAdapterEnabled(reply: @escaping ((Bool) -> Void)) -> Void {
        reply(SMCPowerKit.isPowerAdapterEnabled())
    }
    
    func enablePowerAdapter() -> Void {
        BTPowerState.enablePowerAdapter()
    }
    
    func disablePowerAdapter() -> Void {
        BTPowerState.disablePowerAdapter()
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
    
    func setAdapterSleep(enabled: Bool) {
        BTPreferences.setAdapterSleep(enabled: enabled)
    }
}
