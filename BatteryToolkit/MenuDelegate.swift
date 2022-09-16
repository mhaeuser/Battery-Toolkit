import Cocoa
import os.log

final class MenuDelegate: NSObject, NSMenuDelegate {
    @IBOutlet weak var infoUnknownStateItem: NSMenuItem!

    @IBOutlet weak var infoPowerAdapterEnabledItem: NSMenuItem!
    @IBOutlet weak var infoPowerAdapterDisabledItem: NSMenuItem!

    @IBOutlet weak var infoChargingToMaximumItem: NSMenuItem!
    @IBOutlet weak var infoChargingToFullItem: NSMenuItem!
    @IBOutlet weak var infoChargingUnknownModeItem: NSMenuItem!

    @IBOutlet weak var infoNotChargingItem: NSMenuItem!
    @IBOutlet weak var infoRequestedChargingToMaximumItem: NSMenuItem!
    @IBOutlet weak var infoRequestedChargingToFullItem: NSMenuItem!
    @IBOutlet weak var infoNotChargingUnknownModeItem: NSMenuItem!

    func menuWillOpen(_ menu: NSMenu) {
        BatteryToolkit.getState { (state) -> Void in
            DispatchQueue.main.async {
                let powerNum        = state[BTStateInfo.Keys.power] as? NSNumber
                let chargingNum     = state[BTStateInfo.Keys.charging] as? NSNumber
                let chargingModeNum = state[BTStateInfo.Keys.chargingMode] as? NSNumber

                guard let power = powerNum?.boolValue,
                      let charging = chargingNum?.boolValue,
                      let chargingMode = chargingModeNum?.intValue else {
                    self.infoPowerAdapterDisabledItem.isHidden       = true
                    self.infoPowerAdapterEnabledItem.isHidden        = true
                    self.infoChargingToMaximumItem.isHidden          = true
                    self.infoChargingToFullItem.isHidden             = true
                    self.infoChargingUnknownModeItem.isHidden        = true
                    self.infoNotChargingItem.isHidden                = true
                    self.infoRequestedChargingToMaximumItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden    = true
                    self.infoNotChargingUnknownModeItem.isHidden     = true
                    self.infoUnknownStateItem.isHidden               = false
                    return
                }

                self.infoUnknownStateItem.isHidden = true

                if power {
                    self.infoPowerAdapterDisabledItem.isHidden = true
                    self.infoPowerAdapterEnabledItem.isHidden  = false
                } else {
                    self.infoPowerAdapterEnabledItem.isHidden  = true
                    self.infoPowerAdapterDisabledItem.isHidden = false
                }

                if charging {
                    self.infoNotChargingItem.isHidden                = true
                    self.infoRequestedChargingToMaximumItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden    = true
                    self.infoNotChargingUnknownModeItem.isHidden     = true

                    switch chargingMode {
                        case Int(BTStateInfo.ChargingMode.standard.rawValue),
                            Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                            self.infoChargingToFullItem.isHidden      = true
                            self.infoChargingUnknownModeItem.isHidden = true
                            self.infoChargingToMaximumItem.isHidden   = false

                        case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                            self.infoChargingToMaximumItem.isHidden   = true
                            self.infoChargingUnknownModeItem.isHidden = true
                            self.infoChargingToFullItem.isHidden      = false

                        default:
                            os_log("Unknown charging mode: \(chargingMode)")
                            self.infoChargingToMaximumItem.isHidden   = true
                            self.infoChargingToFullItem.isHidden      = true
                            self.infoChargingUnknownModeItem.isHidden = false
                    }
                } else {
                    self.infoChargingToMaximumItem.isHidden   = true
                    self.infoChargingToFullItem.isHidden      = true
                    self.infoChargingUnknownModeItem.isHidden = true

                    switch chargingMode {
                        case Int(BTStateInfo.ChargingMode.standard.rawValue):
                            self.infoRequestedChargingToMaximumItem.isHidden = true
                            self.infoRequestedChargingToFullItem.isHidden    = true
                            self.infoNotChargingUnknownModeItem.isHidden     = true
                            self.infoNotChargingItem.isHidden                = false

                        case Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                            self.infoNotChargingItem.isHidden                = true
                            self.infoRequestedChargingToFullItem.isHidden    = true
                            self.infoNotChargingUnknownModeItem.isHidden     = true
                            self.infoRequestedChargingToMaximumItem.isHidden = false

                        case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                            self.infoNotChargingItem.isHidden                = true
                            self.infoRequestedChargingToMaximumItem.isHidden = true
                            self.infoNotChargingUnknownModeItem.isHidden     = true
                            self.infoRequestedChargingToFullItem.isHidden    = false

                        default:
                            os_log("Unknown charging mode: \(chargingMode)")
                            self.infoNotChargingItem.isHidden                = true
                            self.infoRequestedChargingToMaximumItem.isHidden = true
                            self.infoRequestedChargingToFullItem.isHidden    = true
                            self.infoNotChargingUnknownModeItem.isHidden     = false
                    }
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
