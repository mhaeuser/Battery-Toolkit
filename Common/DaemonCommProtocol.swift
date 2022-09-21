/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

enum BTDaemonCommProtocolCommands: UInt8 {
    case disablePowerAdapter
    case enablePowerAdapter
    case chargeToFull
    case chargeToMaximum
    case disableCharging
    case removeLegacyHelperFiles
}

@objc public protocol BTDaemonCommProtocol {
    @MainActor func getUniqueId(reply: @Sendable @escaping (NSData?) -> Void) -> Void
    @MainActor func execute(command: UInt8, reply: @Sendable @escaping (Bool) -> Void) -> Void
    @MainActor func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void
    @MainActor func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void
    @MainActor func setSettings(settings: [String: AnyObject]) -> Void
}
