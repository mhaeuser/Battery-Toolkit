/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import BTPreprocessor

internal struct BatteryToolkit {
    @MainActor internal static func startDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonManagement.start(reply: reply)
    }

    @MainActor internal static func approveDaemon(timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {
        BTDaemonManagement.approve(timeout: timeout, reply: reply)
    }
    
    @MainActor internal static func stop() {
        BTDaemonXPCClient.stop()
    }
    
    @MainActor internal static func disablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.disablePowerAdapter(reply: reply)
    }

    @MainActor internal static func enablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.enablePowerAdapter(reply: reply)
    }

    @MainActor internal static func chargeToMaximum(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.chargeToMaximum(reply: reply)
    }

    @MainActor internal static func chargeToFull(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.chargeToFull(reply: reply)
    }

    @MainActor internal static func disableCharging(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.disableCharging(reply: reply)
    }

    @MainActor internal static func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        BTDaemonXPCClient.getState(reply: reply)
    }

    @MainActor internal static func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        BTDaemonXPCClient.getSettings(reply: reply)
    }

    @MainActor internal static func setSettings(settings: [String: AnyObject], reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonXPCClient.setSettings(settings: settings, reply: reply)
    }
    
    @MainActor internal static func unregisterDaemon(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTDaemonManagement.unregister(reply: reply)
    }
}
