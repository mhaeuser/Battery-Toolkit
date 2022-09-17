/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

enum BTHelperCommProtocolCommands: UInt8 {
    case disablePowerAdapter
    case enablePowerAdapter
    case chargeToFull
    case chargeToMaximum
    case disableCharging
    case removeHelperFiles
}

@objc public protocol BTHelperCommProtocol {
    @MainActor func execute(command: UInt8) -> Void
    @MainActor func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void
    @MainActor func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void
    @MainActor func setSettings(settings: [String: AnyObject]) -> Void
}
