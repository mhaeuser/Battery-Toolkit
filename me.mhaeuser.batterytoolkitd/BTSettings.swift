//
// Copyright (C) 2022 - 2023 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTSettings {
    private(set) static var minCharge = BTSettingsInfo.Defaults.minCharge
    private(set) static var maxCharge = BTSettingsInfo.Defaults.maxCharge
    private(set) static var adapterSleep = BTSettingsInfo.Defaults.adapterSleep

    static func readDefaults() {
        self.adapterSleep = UserDefaults.standard.bool(
            forKey: BTSettingsInfo.Keys.adapterSleep
        )

        let minCharge = UserDefaults.standard.integer(
            forKey: BTSettingsInfo.Keys.minCharge
        )
        let maxCharge = UserDefaults.standard.integer(
            forKey: BTSettingsInfo.Keys.maxCharge
        )
        guard
            BTSettingsInfo.chargeLimitsValid(
                minCharge: minCharge,
                maxCharge: maxCharge
            )
        else {
            os_log("Charge limits malformed, restore current values")
            self.writeDefaults()
            return
        }

        self.minCharge = UInt8(minCharge)
        self.maxCharge = UInt8(maxCharge)
    }

    static func removeDefaults() {
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.adapterSleep
        )
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.minCharge
        )
        UserDefaults.standard.removeObject(
            forKey: BTSettingsInfo.Keys.maxCharge
        )

        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    static func getSettings() -> [String: NSObject & Sendable] {
        let minCharge = NSNumber(value: self.minCharge)
        let maxCharge = NSNumber(value: self.maxCharge)
        let adapterSleep = NSNumber(value: self.adapterSleep)
        let settings: [String: NSObject & Sendable] = [
            BTSettingsInfo.Keys.minCharge: minCharge,
            BTSettingsInfo.Keys.maxCharge: maxCharge,
            BTSettingsInfo.Keys.adapterSleep: adapterSleep,
        ]

        return settings
    }

    static func setSettings(
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        let minChargeNum = settings[BTSettingsInfo.Keys.minCharge] as? NSNumber
        let minCharge = minChargeNum?.intValue ??
            Int(BTSettingsInfo.Defaults.minCharge)

        let maxChargeNum = settings[BTSettingsInfo.Keys.maxCharge] as? NSNumber
        let maxCharge = maxChargeNum?.intValue ??
            Int(BTSettingsInfo.Defaults.maxCharge)

        let success = self.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
        )
        guard success else {
            reply(BTError.malformedData.rawValue)
            return
        }

        let adapterSleepNum =
            settings[BTSettingsInfo.Keys.adapterSleep] as? NSNumber
        let adapterSleep = adapterSleepNum?.boolValue ??
            BTSettingsInfo.Defaults.adapterSleep

        self.setAdapterSleep(enabled: adapterSleep)

        self.writeDefaults()

        reply(BTError.success.rawValue)
    }

    private static func setChargeLimits(
        minCharge: Int,
        maxCharge: Int
    ) -> Bool {
        guard
            BTSettingsInfo.chargeLimitsValid(
                minCharge: minCharge,
                maxCharge: maxCharge
            )
        else {
            os_log("Client charge limits malformed, preserve current values")
            return false
        }

        self.minCharge = UInt8(minCharge)
        self.maxCharge = UInt8(maxCharge)

        BTPowerEvents.settingsChanged()

        return true
    }

    private static func setAdapterSleep(enabled: Bool) {
        guard self.adapterSleep != enabled else {
            return
        }

        self.adapterSleep = enabled

        BTPowerState.adapterSleepSettingToggled()
    }

    private static func writeDefaults() {
        assert(
            BTSettingsInfo.chargeLimitsValid(
                minCharge: Int(self.minCharge),
                maxCharge: Int(self.maxCharge)
            )
        )

        UserDefaults.standard.set(
            self.minCharge,
            forKey: BTSettingsInfo.Keys.minCharge
        )
        UserDefaults.standard.set(
            self.maxCharge,
            forKey: BTSettingsInfo.Keys.maxCharge
        )
        UserDefaults.standard.set(
            self.adapterSleep,
            forKey: BTSettingsInfo.Keys.adapterSleep
        )
        //
        // As NSUserDefaults are not automatically synchronized without
        // NSApplication, do so manually.
        //
        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
}
