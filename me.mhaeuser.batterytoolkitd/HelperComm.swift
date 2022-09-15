import Foundation
import os.log
import IOPMPrivate

internal final class BTHelperComm: NSObject, BTHelperCommProtocol {
    private static let helperFiles = [
        BTLegacyHelperInfo.legacyHelperExec,
        BTLegacyHelperInfo.legacyHelperPlist
    ]

    internal func execute(command: UInt8) -> Void {
        switch command {
            case BTHelperCommProtocolCommands.chargeToFull.rawValue:
                BTPowerEvents.chargeToFull()

            case BTHelperCommProtocolCommands.chargeToMaximum.rawValue:
                BTPowerEvents.chargeToMaximum()

            case BTHelperCommProtocolCommands.disablePowerAdapter.rawValue:
                BTPowerState.disablePowerAdapter()

            case BTHelperCommProtocolCommands.enablePowerAdapter.rawValue:
                BTPowerState.enablePowerAdapter()

            case BTHelperCommProtocolCommands.removeHelperFiles.rawValue:
                BTHelperComm.removeHelperFiles()

            default:
                os_log("Unknown command: \(command)")
        }
    }

    internal func getState(reply: @escaping (([String: AnyObject]) -> Void)) -> Void {
        let charging = SMCPowerKit.isChargingEnabled()
        let power    = SMCPowerKit.isPowerAdapterEnabled()
        let mode     = BTPowerEvents.chargeMode

        let state = [
            BTStateInfo.Keys.power: NSNumber(value: power),
            BTStateInfo.Keys.charging: NSNumber(value: charging),
            BTStateInfo.Keys.chargingMode: NSNumber(value: mode.rawValue)
        ]
        reply(state)
    }

    internal func getSettings(reply: @escaping (([String: AnyObject]) -> Void)) {
        let settings = BTSettings.getSettings()
        reply(settings)
    }

    internal func setSettings(settings: [String: AnyObject]) -> Void {
        BTSettings.setSettings(settings: settings)
    }
    
    private static func removeHelperFiles() -> Void {
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
