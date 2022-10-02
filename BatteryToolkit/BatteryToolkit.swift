//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import BTPreprocessor

@MainActor
internal struct BatteryToolkit {
    internal static func startDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonManagement.start(reply: reply)
    }

    internal static func approveDaemon(timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {
        BTDaemonManagement.approve(timeout: timeout, reply: reply)
    }

    internal static func upgradeDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonManagement.upgrade(reply: reply)
    }
    
    internal static func stop() {
        BTDaemonXPCClient.stop()
    }
    
    internal static func disablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.disablePowerAdapter(reply: reply)
    }

    internal static func enablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.enablePowerAdapter(reply: reply)
    }

    internal static func chargeToMaximum(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.chargeToMaximum(reply: reply)
    }

    internal static func chargeToFull(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.chargeToFull(reply: reply)
    }

    internal static func disableCharging(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.disableCharging(reply: reply)
    }

    internal static func getState(reply: @Sendable @escaping (BTError.RawValue, [String: NSObject]) -> Void) {
        BTDaemonXPCClient.getState(reply: reply)
    }

    internal static func getSettings(reply: @Sendable @escaping (BTError.RawValue, [String: NSObject]) -> Void) {
        BTDaemonXPCClient.getSettings(reply: reply)
    }

    internal static func setSettings(settings: [String: NSObject], reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.setSettings(settings: settings, reply: reply)
    }
    
    internal static func removeDaemon(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonManagement.remove(reply: reply)
    }
}
