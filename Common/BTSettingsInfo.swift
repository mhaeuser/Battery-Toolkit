//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

public enum BTSettingsInfo {
    public enum Defaults {
        public static let minCharge: UInt8 = 70
        public static let maxCharge: UInt8 = 80
        public static let adapterSleep = false

        public static let disableAutostart = false
    }

    public enum Bounds {
        public static let minChargeMin: UInt8 = 20
        public static let maxChargeMin: UInt8 = 50
    }

    public enum Keys {
        public static let minCharge = "MinCharge"
        public static let maxCharge = "MaxCharge"
        public static let adapterSleep = "AdapterSleep"

        public static let disableAutostart = "DisableAutostart"
    }

    public static func chargeLimitsValid(
        minCharge: Int,
        maxCharge: Int
    ) -> Bool {
        return BTSettingsInfo.Bounds.minChargeMin <= minCharge &&
            minCharge <= maxCharge &&
            maxCharge <= 100 &&
            BTSettingsInfo.Bounds.maxChargeMin <= maxCharge
    }
}
