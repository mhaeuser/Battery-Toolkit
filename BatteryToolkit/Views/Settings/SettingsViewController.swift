/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa
import os.log

final class SettingsViewController: NSViewController {
    private var currentSettings: [String: NSObject]? = nil

    @IBOutlet var tabView: NSTabView!
    @IBOutlet var generalTab: NSTabViewItem!
    @IBOutlet var backgroundActivityTab: NSTabViewItem!

    @IBOutlet var autostartButton: NSButton!

    @IBOutlet var minChargeTextField: NSTextField!
    @IBOutlet var minChargeSlider: NSSlider!
    
    @IBOutlet var maxChargeTextField: NSTextField!
    @IBOutlet var maxChargeSlider: NSSlider!
    
    @IBOutlet var adapterSleepButton: NSButton!

    private var minChargeVal = BTSettingsInfo.Defaults.minCharge
    @objc dynamic var minChargeNum: NSNumber {
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
                DispatchQueue.main.async {
                    self.minChargeNum = NSNumber(
                        value: BTSettingsInfo.Bounds.minChargeMin
                        )
                }
            } else if value > 100 {
                DispatchQueue.main.async {
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
    @objc dynamic var maxChargeNum: NSNumber {
        get {
            return NSNumber(value: self.maxChargeVal)
        }
        
        set {
            let value = newValue.intValue
            //
            // See minChargeNum for an explanation.
            //
            if value < BTSettingsInfo.Bounds.maxChargeMin {
                DispatchQueue.main.async {
                    self.maxChargeNum = NSNumber(
                        value: BTSettingsInfo.Bounds.maxChargeMin
                        )
                }
            } else if value > 100 {
                DispatchQueue.main.async {
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

    private func setMinCharge(value: Int) {
        self.minChargeNum = NSNumber(value: value)
    }

    private func setMaxCharge(value: Int) {
        self.maxChargeNum = NSNumber(value: value)
    }

    private func setAdapterSleep(value: Bool) {
        self.adapterSleepButton.state = value ?
            NSControl.StateValue.off :
            NSControl.StateValue.on
    }

    private func initGeneralState() {
        let disableAutostart = UserDefaults.standard.bool(
            forKey: BTSettingsInfo.Keys.disableAutostart
            )
        self.autostartButton.state = disableAutostart ?
            NSControl.StateValue.off :
            NSControl.StateValue.on
    }
    
    private func initBackgroundActivityState() {
        BatteryToolkit.getSettings { (error, settings) in
            DispatchQueue.main.async {
                self.currentSettings = settings

                guard error == BTError.success.rawValue else {
                    BTErrorHandler.errorHandler(error: error)
                    return
                }

                let minChargeNum   = settings[BTSettingsInfo.Keys.minCharge] as? NSNumber
                let maxChargeNum   = settings[BTSettingsInfo.Keys.maxCharge] as? NSNumber
                let adapterInfoNum = settings[BTSettingsInfo.Keys.adapterSleep] as? NSNumber

                let minCharge    = minChargeNum?.intValue    ?? Int(BTSettingsInfo.Defaults.minCharge)
                let maxCharge    = maxChargeNum?.intValue    ?? Int(BTSettingsInfo.Defaults.maxCharge)
                let adapterSleep = adapterInfoNum?.boolValue ?? BTSettingsInfo.Defaults.adapterSleep

                self.setMinCharge(value: minCharge)
                self.setMaxCharge(value: maxCharge)
                self.setAdapterSleep(value: adapterSleep)
            }
        }
    }
    
    @IBAction func cancelButtonAction(_ sender: NSButton) {
        self.view.window?.windowController?.close()
    }
    
    @IBAction func doneButtonAction(_ sender: NSButton) {
        let disableAutostart = autostartButton.state != .on
        let success = disableAutostart ?
            BTLoginItem.disable() :
            BTLoginItem.enable()

        // FIXME: Handle error?
        if success {
            UserDefaults.standard.setValue(
                disableAutostart,
                forKey: BTSettingsInfo.Keys.disableAutostart
                )
        }

        let settings: [String: NSObject] = [
            BTSettingsInfo.Keys.minCharge: self.minChargeNum,
            BTSettingsInfo.Keys.maxCharge: self.maxChargeNum,
            BTSettingsInfo.Keys.adapterSleep: NSNumber(
                value: self.adapterSleepButton.state == NSControl.StateValue.off
                )
        ]

        guard settings != currentSettings else {
            os_log("Background Activity settings have not changed, ignoring")
            self.view.window?.windowController?.close()
            return
        }

        BTDaemonXPCClient.setSettings(settings: settings) { error in
            DispatchQueue.main.async {
                guard error != BTError.success.rawValue else {
                    self.view.window?.windowController?.close()
                    return
                }

                BTErrorHandler.errorHandler(
                    error: error,
                    window: self.view.window
                    )
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        initGeneralState()
        initBackgroundActivityState()
        self.view.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    internal func selectGeneralTab() {
        self.tabView.selectTabViewItem(self.generalTab)
    }

    internal func selectBackgroundActivityTab() {
        self.tabView.selectTabViewItem(self.backgroundActivityTab)
        self.updateViewConstraints()
    }
}
