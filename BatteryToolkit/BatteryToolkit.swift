/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import BTPreprocessor

@MainActor
internal struct BatteryToolkit {
    internal static func startDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonManagement.startDaemon(reply: reply)
    }

    internal static func approveDaemon() {
        BTDaemonManagement.approveDaemon()
    }
    
    internal static func stop() {
        BTDaemonXPCClient.stop()
    }
    
    internal static func disablePowerAdapter() {
        BTDaemonXPCClient.disablePowerAdapter()
    }

    internal static func enablePowerAdapter() {
        BTDaemonXPCClient.enablePowerAdapter()
    }

    internal static func chargeToMaximum() {
        BTDaemonXPCClient.chargeToMaximum()
    }

    internal static func chargeToFull() {
        BTDaemonXPCClient.chargeToFull()
    }

    internal static func disableCharging() {
        BTDaemonXPCClient.disableCharging()
    }

    internal static func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        BTDaemonXPCClient.getState(reply: reply)
    }

    internal static func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        BTDaemonXPCClient.getSettings(reply: reply)
    }

    internal static func setSettings(settings: [String: AnyObject]) {
        BTDaemonXPCClient.setSettings(settings: settings)
    }
    
    internal static func unregisterDaemon(reply: @Sendable @escaping (Bool) -> Void) {
        BTDaemonManagement.unregisterDaemon(reply: reply)
    }
}
