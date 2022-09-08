import Foundation
import IOPMPrivate

public final class BTHelperComm: NSObject, BTHelperCommProtocol {
    private static let helperFiles = [
        "/Library/PrivilegedHelperTools/me.mhaeuser.batterytoolkitd",
        BTLegacyHelperInfo.legacyHelperPlist
        ]

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
        BTSettings.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
    
    func setAdapterSleep(enabled: Bool) {
        BTSettings.setAdapterSleep(enabled: enabled)
    }
    
    func removeHelperFiles() -> Void {
        if CommandLine.arguments.count <= 0 {
            NSLog("No command line arguments provided")
            return
        }
        
        if CommandLine.arguments[0] != BTHelperComm.helperFiles[0] {
            NSLog("Helper launched from unexpected location: \(CommandLine.arguments[0])")
            return
        }

        do {
            for path in BTHelperComm.helperFiles {
                try FileManager.default.removeItem(atPath: path)
            }
        } catch let error as NSError {
            print("An error took place: \(error)")
        }
    }
}
