//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTCommandsMenuDelegate: NSObject, NSMenuDelegate {
    @IBOutlet private var infoUnknownStateItem: NSMenuItem!
    @IBOutlet private var infoPausedItem: NSMenuItem!

    @IBOutlet private var infoPowerAdapterEnabledItem: NSMenuItem!
    @IBOutlet private var infoPowerAdapterDisabledItem: NSMenuItem!

    @IBOutlet private var infoChargingToLimitItem: NSMenuItem!
    @IBOutlet private var infoChargingToFullItem: NSMenuItem!
    @IBOutlet private var infoChargingUnknownModeItem: NSMenuItem!

    @IBOutlet private var infoNotChargingItem: NSMenuItem!
    @IBOutlet private var infoRequestedChargingToLimitItem: NSMenuItem!
    @IBOutlet private var infoRequestedChargingToFullItem: NSMenuItem!
    @IBOutlet private var infoNotChargingUnknownModeItem: NSMenuItem!

    @IBOutlet private var disablePowerAdapterItem: NSMenuItem!
    @IBOutlet private var enablePowerAdapterItem: NSMenuItem!

    @IBOutlet private var chargeToFullNowItem: NSMenuItem!
    @IBOutlet private var chargeToLimitNowItem: NSMenuItem!
    @IBOutlet private var disableChargingItem: NSMenuItem!

    @IBOutlet private var requestChargingToFullItem: NSMenuItem!
    @IBOutlet private var requestChargingToLimitItem: NSMenuItem!
    @IBOutlet private var cancelChargingRequestItem: NSMenuItem!

    @IBOutlet private var pauseActivityItem: NSMenuItem!
    @IBOutlet private var resumeActivityItem: NSMenuItem!

    private var refreshTimer: DispatchSourceTimer? = nil

    private func hidePowerItems() {
        self.disablePowerAdapterItem.isHidden = true
        self.enablePowerAdapterItem.isHidden = true
        self.chargeToFullNowItem.isHidden = true
        self.chargeToLimitNowItem.isHidden = true
        self.disableChargingItem.isHidden = true
        self.requestChargingToFullItem.isHidden = true
        self.requestChargingToLimitItem.isHidden = true
        self.cancelChargingRequestItem.isHidden = true
    }

    private func refresh() async {
        do {
            let state = try await BTActions.getState()

            let enabledNum = state[BTStateInfo.Keys.enabled] as? NSNumber
            guard let enabled = enabledNum?.boolValue else {
                throw BTError.commFailed
            }

            guard enabled else {
                self.infoUnknownStateItem.isHidden = true
                self.infoPowerAdapterEnabledItem.isHidden = true
                self.infoPowerAdapterDisabledItem.isHidden = true
                self.infoChargingToLimitItem.isHidden = true
                self.infoChargingToFullItem.isHidden = true
                self.infoChargingUnknownModeItem.isHidden = true
                self.infoNotChargingItem.isHidden = true
                self.infoRequestedChargingToLimitItem.isHidden = true
                self.infoRequestedChargingToFullItem.isHidden = true
                self.infoNotChargingUnknownModeItem.isHidden = true

                self.hidePowerItems()

                self.pauseActivityItem.isHidden = true
                self.resumeActivityItem.isHidden = false

                self.infoPausedItem.isHidden = false

                return
            }

            self.infoPausedItem.isHidden = true

            self.resumeActivityItem.isHidden = true
            self.pauseActivityItem.isHidden = false

            let powerDisabledNum =
            state[BTStateInfo.Keys.powerDisabled] as? NSNumber
            let connectedNum =
            state[BTStateInfo.Keys.connected] as? NSNumber
            let chargingDisabledNum =
            state[BTStateInfo.Keys.chargingDisabled] as? NSNumber
            let progressNum = state[BTStateInfo.Keys.progress] as? NSNumber
            let chargingModeNum =
            state[BTStateInfo.Keys.chargingMode] as? NSNumber
            let maxChargeNum =
            state[BTStateInfo.Keys.maxCharge] as? NSNumber

            guard
                let powerDisabled = powerDisabledNum?.boolValue,
                let connected = connectedNum?.boolValue,
                let chargingDisabled = chargingDisabledNum?.boolValue,
                let progress = progressNum?.intValue,
                let chargingMode = chargingModeNum?.intValue,
                let maxCharge = maxChargeNum?.intValue
            else {
                throw BTError.commFailed
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
                self.infoRequestedChargingToLimitItem.isHidden = true
                self.infoRequestedChargingToFullItem.isHidden = true
                self.infoNotChargingUnknownModeItem.isHidden = true
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue),
                    Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true
                    self.infoChargingToLimitItem.isHidden = false
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.infoChargingToLimitItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = false
                    
                default:
                    os_log("Unknown charging mode: \(chargingMode)")
                    self.infoChargingToLimitItem.isHidden = true
                    self.infoChargingToFullItem.isHidden = true
                    self.infoChargingUnknownModeItem.isHidden = false
                }
            } else {
                self.infoChargingToLimitItem.isHidden = true
                self.infoChargingToFullItem.isHidden = true
                self.infoChargingUnknownModeItem.isHidden = true
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue):
                    self.infoRequestedChargingToLimitItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoNotChargingItem.isHidden = false
                    
                case Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoRequestedChargingToLimitItem.isHidden = false
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToLimitItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = false
                    
                default:
                    os_log("Unknown charging mode: \(chargingMode)")
                    self.infoNotChargingItem.isHidden = true
                    self.infoRequestedChargingToLimitItem.isHidden = true
                    self.infoRequestedChargingToFullItem.isHidden = true
                    self.infoNotChargingUnknownModeItem.isHidden = false
                }
            }
            
            let chargeBelowMax = progress <= BTStateInfo.ChargingProgress
                .belowMax.rawValue
            let chargeBelowFull = progress <= BTStateInfo.ChargingProgress
                .belowFull.rawValue

            self.infoChargingToLimitItem.title = "Charging to \(maxCharge) %"
            self.infoRequestedChargingToLimitItem.title = "Requested Charging to \(maxCharge) %"

            self.chargeToLimitNowItem.title = "Charge to \(maxCharge) % Now"
            self.requestChargingToLimitItem.title = "Request Charging to \(maxCharge) % Now"

            if connected {
                self.requestChargingToFullItem.isHidden = true
                self.requestChargingToLimitItem.isHidden = true
                self.cancelChargingRequestItem.isHidden = true
                self.disableChargingItem.isHidden = chargingDisabled
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue),
                    Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.chargeToLimitNowItem
                        .isHidden = !chargingDisabled || !chargeBelowMax
                    self.chargeToFullNowItem.isHidden = !chargeBelowFull
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.chargeToFullNowItem.isHidden = true
                    self.chargeToLimitNowItem.isHidden = !chargeBelowMax
                    
                default:
                    self.chargeToFullNowItem.isHidden = !chargeBelowFull
                    self.chargeToLimitNowItem.isHidden = !chargeBelowMax
                }
            } else {
                self.chargeToFullNowItem.isHidden = true
                self.chargeToLimitNowItem.isHidden = true
                self.disableChargingItem.isHidden = true
                
                switch chargingMode {
                case Int(BTStateInfo.ChargingMode.standard.rawValue):
                    self.cancelChargingRequestItem.isHidden = true
                    self.requestChargingToFullItem
                        .isHidden = !chargeBelowFull
                    self.requestChargingToLimitItem
                        .isHidden = !chargeBelowMax
                    
                case Int(BTStateInfo.ChargingMode.toLimit.rawValue):
                    self.requestChargingToLimitItem.isHidden = true
                    self.requestChargingToFullItem
                        .isHidden = !chargeBelowFull
                    self.cancelChargingRequestItem.isHidden = false
                    
                case Int(BTStateInfo.ChargingMode.toFull.rawValue):
                    self.requestChargingToFullItem.isHidden = true
                    self.requestChargingToLimitItem
                        .isHidden = !chargeBelowMax
                    self.cancelChargingRequestItem.isHidden = false
                    
                default:
                    self.requestChargingToFullItem
                        .isHidden = !chargeBelowFull
                    self.requestChargingToLimitItem
                        .isHidden = !chargeBelowMax
                    self.cancelChargingRequestItem.isHidden = false
                }
            }
        } catch {
            self.infoPowerAdapterEnabledItem.isHidden = true
            self.infoPowerAdapterDisabledItem.isHidden = true
            self.infoChargingToLimitItem.isHidden = true
            self.infoChargingToFullItem.isHidden = true
            self.infoChargingUnknownModeItem.isHidden = true
            self.infoNotChargingItem.isHidden = true
            self.infoRequestedChargingToLimitItem.isHidden = true
            self.infoRequestedChargingToFullItem.isHidden = true
            self.infoNotChargingUnknownModeItem.isHidden = true

            self.hidePowerItems()

            self.infoUnknownStateItem.isHidden = false

            BTErrorHandler.errorHandler(error: error)
        }
    }

    func menuWillOpen(_: NSMenu) {
        assert(self.refreshTimer == nil)

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.setEventHandler {
            Task {
                await self.refresh()
            }
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

    @IBAction private func quitHandler(sender _: NSMenuItem) {
        BTAppPrompts.promptQuit()
    }

    @IBAction private func disablePowerAdapterHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.disablePowerAdapter()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func enablePowerAdapterHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.enablePowerAdapter()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func chargeToLimitHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.chargeToLimit()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func chargeToFullHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.chargeToFull()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func disableChargingHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.disableCharging()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func pauseActivityHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.pauseActivity()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }

    @IBAction private func resumeActivityHandler(sender _: NSMenuItem) {
        Task {
            do {
                try await BTActions.resumeActiivty()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }
        }
    }
}
