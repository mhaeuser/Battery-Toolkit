//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@MainActor
internal final class BTSettingsViewController: NSViewController {
    private var currentSettings: [String: NSObject]? = nil

    @IBOutlet private var tabView: NSTabView!
    @IBOutlet private var generalTab: NSTabViewItem!
    @IBOutlet private var backgroundActivityTab: NSTabViewItem!

    @IBOutlet private var autostartButton: NSButton!

    @IBOutlet private var minChargeTextField: NSTextField!
    @IBOutlet private var minChargeSlider: NSSlider!

    @IBOutlet private var maxChargeTextField: NSTextField!
    @IBOutlet private var maxChargeSlider: NSSlider!

    @IBOutlet private var adapterSleepButton: NSButton!

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

    @IBAction private func cancelButtonAction(_: NSButton) {
        self.view.window?.windowController?.close()
    }

    @IBAction private func doneButtonAction(_: NSButton) {
        let disableAutostart = self.autostartButton.state != .on
        let success = disableAutostart ?
            BTLoginItem.disable() :
            BTLoginItem.enable()

        // FIXME: Handle error?
        if success {
            UserDefaults.standard.setValue(
                disableAutostart,
                forKey: BTSettingsInfo.Keys.disableAutostart
            )
        } else {
            BTErrorHandler.errorHandler(
                error: BTError.unknown.rawValue,
                window: self.view.window
            )
        }

        let settings: [String: NSObject] = [
            BTSettingsInfo.Keys.minCharge: self.minChargeNum,
            BTSettingsInfo.Keys.maxCharge: self.maxChargeNum,
            BTSettingsInfo.Keys.adapterSleep: NSNumber(
                value: self.adapterSleepButton.state == NSControl.StateValue.off
            ),
        ]

        guard settings != self.currentSettings else {
            os_log("Background Activity settings have not changed, ignoring")
            //
            // If the previous operations failed, we displayed an error prompt
            // and must not close the window.
            //
            if !success {
                self.view.window?.windowController?.close()
            }

            return
        }

        BTDaemonXPCClient.setSettings(settings: settings) { error in
            DispatchQueue.main.async {
                //
                // If the previous operations failed, we already displayed an
                // error prompt and must not close the window.
                //
                guard success else {
                    return
                }

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
        self.initGeneralState()
        self.initBackgroundActivityState()
        self.view.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    func selectGeneralTab() {
        self.tabView.selectTabViewItem(self.generalTab)
    }

    func selectBackgroundActivityTab() {
        self.tabView.selectTabViewItem(self.backgroundActivityTab)
        self.updateViewConstraints()
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
        BTActions.getSettings { error, settings in
            DispatchQueue.main.async {
                self.currentSettings = settings

                guard error == BTError.success.rawValue else {
                    BTErrorHandler.errorHandler(error: error)
                    return
                }

                let minChargeNum =
                    settings[BTSettingsInfo.Keys.minCharge] as? NSNumber
                let maxChargeNum =
                    settings[BTSettingsInfo.Keys.maxCharge] as? NSNumber
                let adapterInfoNum =
                    settings[BTSettingsInfo.Keys.adapterSleep] as? NSNumber

                let minCharge = minChargeNum?.intValue ??
                    Int(BTSettingsInfo.Defaults.minCharge)
                let maxCharge = maxChargeNum?.intValue ??
                    Int(BTSettingsInfo.Defaults.maxCharge)
                let adapterSleep = adapterInfoNum?.boolValue ??
                    BTSettingsInfo.Defaults.adapterSleep

                self.setMinCharge(value: minCharge)
                self.setMaxCharge(value: maxCharge)
                self.setAdapterSleep(value: adapterSleep)
            }
        }
    }
}
