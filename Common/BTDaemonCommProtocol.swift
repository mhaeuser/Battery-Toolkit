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
        reply: @Sendable @escaping (NSData?) -> Void
    )

    @MainActor func execute(
        authData: NSData?,
        command: UInt8,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    )

    @MainActor func getState(
        reply: @Sendable @escaping ([String: NSObject]) -> Void
    )

    @MainActor func getSettings(
        reply: @Sendable @escaping ([String: NSObject]) -> Void
    )

    @MainActor func setSettings(
        authData: NSData?,
        settings: [String: NSObject],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    )
}
