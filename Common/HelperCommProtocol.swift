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
    func execute(command: UInt8) -> Void
    func getState(reply: @escaping (([String: AnyObject]) -> Void)) -> Void
    func getSettings(reply: @escaping (([String: AnyObject]) -> Void)) -> Void
    func setSettings(settings: [String: AnyObject]) -> Void
}
