import Cocoa
import os.log

final class MenuDelegate: NSObject, NSMenuDelegate {
    @IBOutlet weak var powerAdapterExtraItem: NSMenuItem!
    @IBOutlet weak var chargingExtraItem: NSMenuItem!

    private static let powerAdapterPrefix = "Power Adapter: "

    func menuWillOpen(_ menu: NSMenu) {
        BatteryToolkit.getState { (state) -> Void in
            DispatchQueue.main.async {
                let powerNum        = state[BTStateInfo.Keys.power] as? NSNumber
                let chargingNum     = state[BTStateInfo.Keys.charging] as? NSNumber
                let chargingModeNum = state[BTStateInfo.Keys.chargingMode] as? NSNumber

                let power        = powerNum?.boolValue ?? true
                let charging     = chargingNum?.boolValue ?? true
                let chargingMode = chargingModeNum?.intValue ?? Int(BTStateInfo.ChargingMode.standard.rawValue)

                self.powerAdapterExtraItem.title = MenuDelegate.powerAdapterPrefix + (power ? "Enabled" : "Disabled")
                if charging {
                    switch chargingMode {
                        case Int(BTStateInfo.ChargingMode.standard.rawValue),
                            Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                            self.chargingExtraItem.title = "Charging To Maximum"

                        case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                            self.chargingExtraItem.title = "Charging To Full"

                        default:
                            os_log("Unknown charging mode: \(chargingMode)")
                    }
                } else {
                    self.chargingExtraItem.title = "Charging On Hold"
                }
            }
        }
    }

    @IBAction private func disablePowerAdapterHandler(sender: NSMenuItem) {
        BatteryToolkit.disablePowerAdapter()
    }

    @IBAction private func enablePowerAdapterHandler(sender: NSMenuItem) {
        BatteryToolkit.enablePowerAdapter()
    }

    @IBAction private func chargeToMaximumHandler(sender: NSMenuItem) {
        BatteryToolkit.chargeToMaximum()
    }

    @IBAction private func chargeToFullHandler(sender: NSMenuItem) {
        BatteryToolkit.chargeToFull()
    }
}
