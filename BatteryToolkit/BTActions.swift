//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation

@MainActor
internal enum BTActions {
    static func startDaemon(
        reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
    ) {
        BTDaemonManagement.start(reply: reply)
    }

    static func approveDaemon(
        timeout: UInt8,
        reply: @escaping @Sendable (Bool) -> Void
    ) {
        BTDaemonManagement.approve(timeout: timeout, reply: reply)
    }

    static func upgradeDaemon(
        reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
    ) {
        BTDaemonManagement.upgrade(reply: reply)
    }

    static func stop() {
        BTDaemonXPCClient.stop()
    }

    static func disablePowerAdapter(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonXPCClient.disablePowerAdapter(reply: reply)
    }

    static func enablePowerAdapter(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonXPCClient.enablePowerAdapter(reply: reply)
    }

    static func chargeToMaximum(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonXPCClient.chargeToMaximum(reply: reply)
    }

    static func chargeToFull(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonXPCClient.chargeToFull(reply: reply)
    }

    static func disableCharging(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonXPCClient.disableCharging(reply: reply)
    }

    static func getState(
        reply: @Sendable @escaping (BTError.RawValue, [String: NSObject & Sendable])
            -> Void
    ) {
        BTDaemonXPCClient.getState(reply: reply)
    }

    static func getSettings(
        reply: @Sendable @escaping (BTError.RawValue, [String: NSObject & Sendable])
            -> Void
    ) {
        BTDaemonXPCClient.getSettings(reply: reply)
    }

    static func setSettings(
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonXPCClient.setSettings(settings: settings, reply: reply)
    }

    static func removeDaemon(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTDaemonManagement.remove(reply: reply)
    }
}
