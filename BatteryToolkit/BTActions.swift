//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation

@MainActor
internal enum BTActions {
    static func startDaemon() async -> BTDaemonManagement.Status {
        return await BTDaemonManagement.start()
    }

    static func approveDaemon(timeout: UInt8) async throws {
        try await BTDaemonManagement.approve(timeout: timeout)
    }

    static func upgradeDaemon() async -> BTDaemonManagement.Status {
        return await BTDaemonManagement.upgrade()
    }

    static func stop() {
        BTDaemonXPCClient.disconnectDaemon()
    }

    static func disablePowerAdapter() async throws {
        try await BTDaemonXPCClient.disablePowerAdapter()
    }

    static func enablePowerAdapter() async throws {
        try await BTDaemonXPCClient.enablePowerAdapter()
    }

    static func chargeToMaximum() async throws {
        try await BTDaemonXPCClient.chargeToMaximum()
    }

    static func chargeToFull() async throws {
        try await BTDaemonXPCClient.chargeToFull()
    }

    static func disableCharging() async throws {
        try await BTDaemonXPCClient.disableCharging()
    }

    static func getState() async throws -> [String: NSObject & Sendable] {
        return try await BTDaemonXPCClient.getState()
    }

    static func getSettings() async throws -> [String: NSObject & Sendable] {
        return try await BTDaemonXPCClient.getSettings()
    }

    static func setSettings(settings: [String: NSObject & Sendable]) async throws {
        try await BTDaemonXPCClient.setSettings(settings: settings)
    }

    static func removeDaemon() async throws {
        try await BTDaemonManagement.remove()
    }
}
