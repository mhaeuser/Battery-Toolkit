//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation

internal enum BTActions {
    @BTBackgroundActor static func startDaemon() async -> BTDaemonManagement.Status {
        return await BTDaemonManagement.start()
    }

    static func approveDaemon(timeout: UInt8) async throws {
        try await BTDaemonManagement.approve(timeout: timeout)
    }

    @BTBackgroundActor static func upgradeDaemon() async -> BTDaemonManagement.Status {
        return await BTDaemonManagement.upgrade()
    }

    @BTBackgroundActor static func stop() {
        BTDaemonXPCClient.disconnectDaemon()
    }

    @BTBackgroundActor static func disablePowerAdapter() async throws {
        try await BTDaemonXPCClient.disablePowerAdapter()
    }

    @BTBackgroundActor static func enablePowerAdapter() async throws {
        try await BTDaemonXPCClient.enablePowerAdapter()
    }

    @BTBackgroundActor static func chargeToLimit() async throws {
        try await BTDaemonXPCClient.chargeToLimit()
    }

    @BTBackgroundActor static func chargeToFull() async throws {
        try await BTDaemonXPCClient.chargeToFull()
    }

    @BTBackgroundActor static func disableCharging() async throws {
        try await BTDaemonXPCClient.disableCharging()
    }

    @BTBackgroundActor static func getState() async throws -> [String: NSObject & Sendable] {
        return try await BTDaemonXPCClient.getState()
    }

    @BTBackgroundActor static func getSettings() async throws -> [String: NSObject & Sendable] {
        return try await BTDaemonXPCClient.getSettings()
    }

    @BTBackgroundActor static func setSettings(settings: [String: NSObject & Sendable]) async throws {
        try await BTDaemonXPCClient.setSettings(settings: settings)
    }

    @BTBackgroundActor static func removeDaemon() async throws {
        try await BTDaemonManagement.remove()
    }

    @BTBackgroundActor static func pauseActivity() async throws {
        try await BTDaemonXPCClient.pauseActivity()
    }

    @BTBackgroundActor static func resumeActiivty() async throws {
        try await BTDaemonXPCClient.resumeActivity()
    }
}
