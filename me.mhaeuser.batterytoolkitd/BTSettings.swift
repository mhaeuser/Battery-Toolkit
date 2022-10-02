//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTSettings {
    internal private(set) static var minCharge =
        BTSettingsInfo.Defaults.minCharge
    internal private(set) static var maxCharge =
        BTSettingsInfo.Defaults.maxCharge
    internal private(set) static var adapterSleep =
        BTSettingsInfo.Defaults.adapterSleep

    private static func writeDefaults() {
        assert(
            BTSettingsInfo.chargeLimitsValid(
                minCharge: Int(BTSettings.minCharge),
                maxCharge: Int(BTSettings.maxCharge)
            )
        )

        UserDefaults.standard.set(
            BTSettings.minCharge,
            forKey: BTSettingsInfo.Keys.minCharge
        )
        UserDefaults.standard.set(
            BTSettings.maxCharge,
            forKey: BTSettingsInfo.Keys.maxCharge
        )
        UserDefaults.standard.set(
            BTSettings.adapterSleep,
            forKey: BTSettingsInfo.Keys.adapterSleep
        )

        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    internal static func readDefaults() {
        BTSettings.adapterSleep = UserDefaults.standard.bool(
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

        BTSettings.minCharge = UInt8(minCharge)
        BTSettings.maxCharge = UInt8(maxCharge)
    }

    internal static func removeDefaults() {
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

        BTSettings.minCharge = UInt8(minCharge)
        BTSettings.maxCharge = UInt8(maxCharge)

        BTPowerEvents.settingsChanged()

        return true
    }

    private static func setAdapterSleep(enabled: Bool) {
        guard BTSettings.adapterSleep != enabled else {
            return
        }

        BTSettings.adapterSleep = enabled

        BTPowerState.adapterSleepPreferenceToggled()
    }

    internal static func getSettings() -> [String: NSObject] {
        let minCharge = NSNumber(value: BTSettings.minCharge)
        let maxCharge = NSNumber(value: BTSettings.maxCharge)
        let adapterSleep = NSNumber(value: BTSettings.adapterSleep)
        let settings: [String: NSObject] = [
            BTSettingsInfo.Keys.minCharge: minCharge,
            BTSettingsInfo.Keys.maxCharge: maxCharge,
            BTSettingsInfo.Keys.adapterSleep: adapterSleep,
        ]

        return settings
    }

    internal static func setSettings(
        settings: [String: NSObject],
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

        let adapterInfoNum =
            settings[BTSettingsInfo.Keys.adapterSleep] as? NSNumber
        let adapterSleep = adapterInfoNum?.boolValue ??
            BTSettingsInfo.Defaults.adapterSleep

        self.setAdapterSleep(enabled: adapterSleep)

        self.writeDefaults()

        reply(BTError.success.rawValue)
    }
}
