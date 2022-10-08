//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

enum BTDaemonCommCommand: UInt8 {
    case disablePowerAdapter
    case enablePowerAdapter
    case chargeToFull
    case chargeToMaximum
    case disableCharging
    case prepareUpdate
    case finishUpdate
    case removeLegacyHelperFiles
    case prepareDisable
    case isSupported
}

@objc internal protocol BTDaemonCommProtocol {
    @MainActor func getUniqueId(
        reply: @Sendable @escaping (Data?) -> Void
    )

    @MainActor func execute(
        authData: Data?,
        command: UInt8,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    )

    @MainActor func getState(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    )

    @MainActor func getSettings(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    )

    @MainActor func setSettings(
        authData: Data?,
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    )
}
