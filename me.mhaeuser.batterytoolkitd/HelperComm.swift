import Foundation
import os.log
import IOPMPrivate

internal final class BTHelperComm: NSObject, BTHelperCommProtocol {
    private static let helperFiles = [
        BTLegacyHelperInfo.legacyHelperExec,
        BTLegacyHelperInfo.legacyHelperPlist
    ]

    internal func getState(reply: @escaping (([String: AnyObject]) -> Void)) -> Void {
        let state = [
            "Adapter": NSNumber(value: SMCPowerKit.isPowerAdapterEnabled())
        ]
        reply(state)
    }
    
    internal func enablePowerAdapter() -> Void {
        BTPowerState.enablePowerAdapter()
    }
    
    internal func disablePowerAdapter() -> Void {
        BTPowerState.disablePowerAdapter()
    }
    
    internal func chargeToMaximum() -> Void {
        BTPowerEvents.chargeToMaximum()
    }

    internal func chargeToFull() -> Void {
        BTPowerEvents.chargeToFull()
    }

    internal func getSettings(reply: @escaping (([String: AnyObject]) -> Void)) {
        let settings = BTSettings.getSettings()
        reply(settings)
    }

    internal func setSettings(settings: [String: AnyObject]) -> Void {
        BTSettings.setSettings(settings: settings)
    }
    
    internal func removeHelperFiles() -> Void {
        if CommandLine.arguments.count <= 0 {
            os_log("No command line arguments provided")
            return
        }
        
        if CommandLine.arguments[0] != BTHelperComm.helperFiles[0] {
            os_log("Helper launched from unexpected location: \(CommandLine.arguments[0])")
            return
        }

        do {
            for path in BTHelperComm.helperFiles {
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            os_log("An error took place: \(error)")
        }
    }
}
