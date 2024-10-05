//
// Copyright (C) 2022 - 2023 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTSettingsViewController: NSViewController {
    private let autostartSetting = "autostart"
    
    private var currentSettings: [String: NSObject & Sendable]? = nil
    
    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var generalTab: NSTabViewItem!
    @IBOutlet private var backgroundActivityTab: NSTabViewItem!
    
    @IBOutlet private var autostartSwitch: NSSwitch!
    
    @IBOutlet private var minChargeTextField: NSTextField!
    @IBOutlet private var minChargeSlider: NSSlider!
    
    @IBOutlet private var maxChargeTextField: NSTextField!
    @IBOutlet private var maxChargeSlider: NSSlider!
    
    @IBOutlet private var adapterSleepSwitch: NSSwitch!
    @IBOutlet private var magSafeSyncSwitch: NSSwitch!
    
    private var minChargeVal = BTSettingsInfo.Defaults.minCharge
    @objc private dynamic var minChargeNum: NSNumber {
        get {
            return NSNumber(value: self.minChargeVal)
        }
        
        set {
            let value = newValue.intValue
            //
            // For clamping, the assignment needs to be async, because otherwise
            // the source control does not get notified of the update. We cannot
            // change the values of the UI controls directly, because this
            // caues the NSSlider to sometimes visually desync with its value.
            //
            if value < BTSettingsInfo.Bounds.minChargeMin {
                Task {
                    self.minChargeNum = NSNumber(
                        value: BTSettingsInfo.Bounds.minChargeMin
                    )
                }
            } else if value > 100 {
                Task {
                    self.minChargeNum = NSNumber(value: 100)
                }
            } else {
                self.minChargeVal = UInt8(value)
                //
                // Clamp the maximum charge to be at least the minimum charge.
                //
                if self.maxChargeVal < self.minChargeVal {
                    self.maxChargeNum = self.minChargeNum
                }
            }
        }
    }
    
    private var maxChargeVal = BTSettingsInfo.Defaults.maxCharge
    @objc private dynamic var maxChargeNum: NSNumber {
        get {
            return NSNumber(value: self.maxChargeVal)
        }
        
        set {
            let value = newValue.intValue
            //
            // See minChargeNum for an explanation.
            //
            if value < BTSettingsInfo.Bounds.maxChargeMin {
                Task {
                    self.maxChargeNum = NSNumber(
                        value: BTSettingsInfo.Bounds.maxChargeMin
                    )
                }
            } else if value > 100 {
                Task {
                    self.maxChargeNum = NSNumber(value: 100)
                }
            } else {
                self.maxChargeVal = UInt8(value)
                //
                // Clamp the maximum charge to be at least the minimum charge.
                //
                if self.maxChargeVal < self.minChargeVal {
                    self.minChargeNum = self.maxChargeNum
                }
            }
        }
    }
    
    @IBAction private func cancelButtonAction(_: NSButton) {
        self.view.window?.windowController?.close()
    }
    
    @IBAction private func doneButtonAction(_: NSButton) {
        let autostart = (self.autostartSwitch.state == .on)
        let success = autostart ?
        BTLoginItem.enable() :
        BTLoginItem.disable()
        
        if success {
            UserDefaults.standard.setValue(
                autostart,
                forKey: self.autostartSetting
            )
        } else {
            BTErrorHandler.errorHandler(
                error: BTError.unknown,
                window: self.view.window
            )
        }
        
        let settings: [String: NSObject & Sendable] = [
            BTSettingsInfo.Keys.minCharge: self.minChargeNum,
            BTSettingsInfo.Keys.maxCharge: self.maxChargeNum,
            BTSettingsInfo.Keys.adapterSleep: NSNumber(
                value: self.adapterSleepSwitch.state == .off
            ),
            BTSettingsInfo.Keys.magSafeSync: NSNumber(
                value: self.magSafeSyncSwitch.state == .on
            ),
        ]
        //
        // Submit the settings to the daemon only when they changed.
        //
        guard !(settings as NSDictionary).isEqual(to: self.currentSettings)
        else {
            os_log("Power settings have not changed, ignoring")
            //
            // If the previous operations failed, we displayed an error prompt
            // and must not close the window.
            //
            if success {
                self.view.window?.windowController?.close()
            }
            
            return
        }
        
        Task {
            do {
                try await BTDaemonXPCClient.setSettings(settings: settings)
                //
                // If the previous operations failed, we already displayed an
                // error prompt and must not close the window.
                //
                guard success else {
                    return
                }
                
                self.view.window?.windowController?.close()
            } catch{
                BTErrorHandler.errorHandler(
                    error: error,
                    window: self.view.window
                )
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.initGeneralState()
        
        Task {
            await self.initPowerState()
            self.view.window?.center()
            //
            // Activate the app when the Settings window is shown, e.g., when
            // invoked from the Menu Bar Extra.
            //
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func selectGeneralTab() {
        self.tabView.selectTabViewItem(self.generalTab)
    }
    
    func selectBackgroundActivityTab() {
        self.tabView.selectTabViewItem(self.backgroundActivityTab)
    }
    
    private func setMinCharge(value: Int) {
        self.minChargeNum = NSNumber(value: value)
    }
    
    private func setMaxCharge(value: Int) {
        self.maxChargeNum = NSNumber(value: value)
    }
    
    private func setAdapterSleep(value: Bool) {
        self.adapterSleepSwitch.state = value ? .off : .on
    }
    
    private func setMagSafeSync(value: Bool) {
        self.magSafeSyncSwitch.state = value ? .on : .off
    }
    
    private func initGeneralState() {
        let autostart = UserDefaults.standard.bool(
            forKey: self.autostartSetting
        )
        self.autostartSwitch.state = autostart ? .on : .off
    }
    
    private func initPowerState() async {
        do {
            let settings = try await BTActions.getSettings()
            self.currentSettings = settings
            
            let minChargeNum =
            settings[BTSettingsInfo.Keys.minCharge] as? NSNumber
            let maxChargeNum =
            settings[BTSettingsInfo.Keys.maxCharge] as? NSNumber
            let adapterSleepNum =
            settings[BTSettingsInfo.Keys.adapterSleep] as? NSNumber
            let magSafeSyncNum =
            settings[BTSettingsInfo.Keys.magSafeSync] as? NSNumber
            
            guard let minCharge = minChargeNum?.intValue,
                  let maxCharge = maxChargeNum?.intValue,
                  let adapterSleep = adapterSleepNum?.boolValue
            else {
                BTErrorHandler.errorHandler(error: BTError.commFailed)
                return
            }
            
            self.setMinCharge(value: minCharge)
            self.setMaxCharge(value: maxCharge)
            self.setAdapterSleep(value: adapterSleep)
            
            if let magSafeSync = magSafeSyncNum?.boolValue {
                self.magSafeSyncSwitch.isEnabled = true
                self.setMagSafeSync(value: magSafeSync)
            } else {
                self.magSafeSyncSwitch.isEnabled = false
            }
        } catch {
            BTErrorHandler.errorHandler(error: error)
        }
    }
}
