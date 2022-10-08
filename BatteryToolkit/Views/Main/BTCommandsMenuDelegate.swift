//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTCommandsMenuDelegate: NSObject, NSMenuDelegate {
    @IBOutlet private var infoUnknownStateItem: NSMenuItem!

    @IBOutlet private var infoPowerAdapterEnabledItem: NSMenuItem!
    @IBOutlet private var infoPowerAdapterDisabledItem: NSMenuItem!

    @IBOutlet private var infoChargingToMaximumItem: NSMenuItem!
    @IBOutlet private var infoChargingToFullItem: NSMenuItem!
    @IBOutlet private var infoChargingUnknownModeItem: NSMenuItem!

    @IBOutlet private var infoNotChargingItem: NSMenuItem!
    @IBOutlet private var infoRequestedChargingToMaximumItem: NSMenuItem!
    @IBOutlet private var infoRequestedChargingToFullItem: NSMenuItem!
    @IBOutlet private var infoNotChargingUnknownModeItem: NSMenuItem!

    @IBOutlet private var disablePowerAdapterItem: NSMenuItem!
    @IBOutlet private var enablePowerAdapterItem: NSMenuItem!

    @IBOutlet private var chargeToFullNowItem: NSMenuItem!
    @IBOutlet private var chargeToMaximumNowItem: NSMenuItem!
    @IBOutlet private var disableChargingItem: NSMenuItem!

    @IBOutlet private var requestChargingToFullItem: NSMenuItem!
    @IBOutlet private var requestChargingToMaximumItem: NSMenuItem!
    @IBOutlet private var cancelChargingRequestItem: NSMenuItem!

    private var refreshTimer: DispatchSourceTimer? = nil

    private func refresh() {
        BTActions.getState { error, state in
            DispatchQueue.main.async {
                guard error == BTError.success.rawValue else {
                    self.infoPowerAdapterEnabledItem.isHidden = true
                    self.infoPowerAdapterDisabledItem.isHidden = true
                    self.infoChargingToMaximumItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToMaximumItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true

                    self.disablePowerAdapterItem.isHidden = true
                    self.enablePowerAdapterItem.isHidden = true
                    self.chargeToFullNowItem.isHidden = true
                    self.chargeToMaximumNowItem.isHidden = true
                    self.disableChargingItem.isHidden = true
                    self.requestChargingToFullItem.isHidden = true
                    self.requestChargingToMaximumItem.isHidden = true
                    self.cancelChargingRequestItem.isHidden = true

                    self.infoUnknownStateItem.isHidden = false

                    BTErrorHandler.errorHandler(error: error)
                    return
                }

                let powerDisabledNum =
                    state[BTStateInfo.Keys.powerDisabled] as? NSNumber
                let connectedNum =
                    state[BTStateInfo.Keys.connected] as? NSNumber
                let chargingDisabledNum =
                    state[BTStateInfo.Keys.chargingDisabled] as? NSNumber
                let progressNum = state[BTStateInfo.Keys.progress] as? NSNumber
                let chargingModeNum =
                    state[BTStateInfo.Keys.chargingMode] as? NSNumber

                guard
                    let powerDisabled = powerDisabledNum?.boolValue,
                    let connected = connectedNum?.boolValue,
                    let chargingDisabled = chargingDisabledNum?.boolValue,
                    let progress = progressNum?.intValue,
                    let chargingMode = chargingModeNum?.intValue
                else {
                    self.infoPowerAdapterDisabledItem.isHidden = true
                    self.infoPowerAdapterEnabledItem.isHidden = true
                    self.infoChargingToMaximumItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToMaximumItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoUnknownStateItem.isHidden = false

                    self.disablePowerAdapterItem.isHidden = true
                    self.enablePowerAdapterItem.isHidden = true
                    self.chargeToFullNowItem.isHidden = true
                    self.chargeToMaximumNowItem.isHidden = true
                    self.requestChargingToFullItem.isHidden = true
                    self.requestChargingToMaximumItem.isHidden = true
                    self.disableChargingItem.isHidden = true
                    self.cancelChargingRequestItem.isHidden = true

                    return
                }

                self.infoUnknownStateItem.isHidden = true

                if !powerDisabled {
                    self.infoPowerAdapterDisabledItem.isHidden = true
                    self.infoPowerAdapterEnabledItem.isHidden = false

                    self.enablePowerAdapterItem.isHidden = true
                    self.disablePowerAdapterItem.isHidden = false
                } else {
                    self.infoPowerAdapterEnabledItem.isHidden = true
                    self.infoPowerAdapterDisabledItem.isHidden = false

                    self.disablePowerAdapterItem.isHidden = true
                    self.enablePowerAdapterItem.isHidden = false
                }

                if !chargingDisabled {
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToMaximumItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true

                    switch chargingMode {
                    case Int(BTStateInfo.ChargingMode.standard.rawValue),
                         Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                        self.infoChargingToFullItem.isHidden = true
                        self.infoChargingUnknownModeItem.isHidden = true
                        self.infoChargingToMaximumItem.isHidden = false

                    case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                        self.infoChargingToMaximumItem.isHidden = true
                        self.infoChargingUnknownModeItem.isHidden = true
                        self.infoChargingToFullItem.isHidden = false

                    default:
                        os_log("Unknown charging mode: \(chargingMode)")
                        self.infoChargingToMaximumItem.isHidden = true
                        self.infoChargingToFullItem.isHidden = true
                        self.infoChargingUnknownModeItem.isHidden = false
                    }
                } else {
                    self.infoChargingToMaximumItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true

                    self.chargeToFullNowItem.isHidden = true
                    self.chargeToMaximumNowItem.isHidden = true

                    switch chargingMode {
                    case Int(BTStateInfo.ChargingMode.standard.rawValue):
                        self.infoRequestedChargingToMaximumItem.isHidden = true
                        self.infoRequestedChargingToFullItem.isHidden = true
                        self.infoNotChargingUnknownModeItem.isHidden = true
                        self.infoNotChargingItem.isHidden = false

                    case Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                        self.infoNotChargingItem.isHidden = true
                        self.infoRequestedChargingToFullItem.isHidden = true
                        self.infoNotChargingUnknownModeItem.isHidden = true
                        self.infoRequestedChargingToMaximumItem.isHidden = false

                    case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                        self.infoNotChargingItem.isHidden = true
                        self.infoRequestedChargingToMaximumItem.isHidden = true
                        self.infoNotChargingUnknownModeItem.isHidden = true
                        self.infoRequestedChargingToFullItem.isHidden = false

                    default:
                        os_log("Unknown charging mode: \(chargingMode)")
                        self.infoNotChargingItem.isHidden = true
                        self.infoRequestedChargingToMaximumItem.isHidden = true
                        self.infoRequestedChargingToFullItem.isHidden = true
                        self.infoNotChargingUnknownModeItem.isHidden = false
                    }
                }

                let chargeBelowMax = progress <= BTStateInfo.ChargingProgress
                    .belowMax.rawValue
                let chargeBelowFull = progress <= BTStateInfo.ChargingProgress
                    .belowFull.rawValue

                if connected {
                    self.requestChargingToFullItem.isHidden = true
                    self.requestChargingToMaximumItem.isHidden = true
                    self.cancelChargingRequestItem.isHidden = true
                    self.disableChargingItem.isHidden = chargingDisabled

                    switch chargingMode {
                    case Int(BTStateInfo.ChargingMode.standard.rawValue),
                         Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                        self.chargeToMaximumNowItem
                            .isHidden = !chargingDisabled || !chargeBelowMax
                        self.chargeToFullNowItem.isHidden = !chargeBelowFull

                    case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                        self.chargeToFullNowItem.isHidden = true
                        self.chargeToMaximumNowItem.isHidden = !chargeBelowMax

                    default:
                        self.chargeToFullNowItem.isHidden = !chargeBelowFull
                        self.chargeToMaximumNowItem.isHidden = !chargeBelowMax
                    }
                } else {
                    self.chargeToFullNowItem.isHidden = true
                    self.chargeToMaximumNowItem.isHidden = true
                    self.disableChargingItem.isHidden = true

                    switch chargingMode {
                    case Int(BTStateInfo.ChargingMode.standard.rawValue):
                        self.cancelChargingRequestItem.isHidden = true
                        self.requestChargingToFullItem
                            .isHidden = !chargeBelowFull
                        self.requestChargingToMaximumItem
                            .isHidden = !chargeBelowMax

                    case Int(BTStateInfo.ChargingMode.toMaximum.rawValue):
                        self.requestChargingToMaximumItem.isHidden = true
                        self.requestChargingToFullItem
                            .isHidden = !chargeBelowFull
                        self.cancelChargingRequestItem.isHidden = false

                    case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                        self.requestChargingToFullItem.isHidden = true
                        self.requestChargingToMaximumItem
                            .isHidden = !chargeBelowMax
                        self.cancelChargingRequestItem.isHidden = false

                    default:
                        self.requestChargingToFullItem
                            .isHidden = !chargeBelowFull
                        self.requestChargingToMaximumItem
                            .isHidden = !chargeBelowMax
                        self.cancelChargingRequestItem.isHidden = false
                    }
                }
            }
        }
    }

    func menuWillOpen(_: NSMenu) {
        assert(self.refreshTimer == nil)

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.setEventHandler {
            self.refresh()
        }
        timer.schedule(deadline: .now(), repeating: 5)
        timer.resume()
        self.refreshTimer = timer
    }

    func menuDidClose(_: NSMenu) {
        assert(self.refreshTimer != nil)

        self.refreshTimer!.cancel()
        self.refreshTimer = nil
    }

    @IBAction private func disablePowerAdapterHandler(sender _: NSMenuItem) {
        BTActions.disablePowerAdapter(reply: BTErrorHandler.completionHandler)
    }

    @IBAction private func enablePowerAdapterHandler(sender _: NSMenuItem) {
        BTActions.enablePowerAdapter(reply: BTErrorHandler.completionHandler)
    }

    @IBAction private func chargeToMaximumHandler(sender _: NSMenuItem) {
        BTActions.chargeToMaximum(reply: BTErrorHandler.completionHandler)
    }

    @IBAction private func chargeToFullHandler(sender _: NSMenuItem) {
        BTActions.chargeToFull(reply: BTErrorHandler.completionHandler)
    }

    @IBAction private func disableChargingHandler(sender _: NSMenuItem) {
        BTActions.disableCharging(reply: BTErrorHandler.completionHandler)
    }
}
