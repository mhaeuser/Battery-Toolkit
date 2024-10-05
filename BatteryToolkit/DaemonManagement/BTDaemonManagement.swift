//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

internal enum BTDaemonManagement {
    @MainActor static func start() async -> BTDaemonManagement.Status {
        let daemonId = try? await BTDaemonXPCClient.getUniqueId()
        if self.daemonUpToDate(daemonId: daemonId) {
            os_log("Daemon is up-to-date, skip install")
            return .enabled
        }

        if #available(macOS 13.0, *) {
            return await self.Service.register()
        } else {
            return await self.Legacy.register()
        }
    }

    @MainActor static func upgrade() async -> BTDaemonManagement.Status {
        if #available(macOS 13.0, *) {
            return await self.Service.upgrade()
        } else {
            //
            // There is no upgrade path to legacy daemons.
            //
            assertionFailure()
            return .notRegistered
        }
    }

    static func approve(timeout: UInt8) async throws {
        if #available(macOS 13.0, *) {
            try await self.Service.approve(timeout: timeout)
        } else {
            //
            // Approval is exclusive to SMAppService daemons.
            //
            assertionFailure()
        }
    }

    @MainActor static func remove() async throws {
        let authData = try await BTAppXPCClient.getDaemonAuthorization()

        _ = try await BTDaemonXPCClient.prepareDisable(authData: authData)
        if #available(macOS 13.0, *) {
            try self.Service.unregister()
        } else {
            let simpleAuth = SimpleAuth.fromData(authData: authData)
            guard let simpleAuth else {
                throw BTError.notAuthorized
            }

            self.Legacy.unregister(simpleAuth: simpleAuth)
        }
    }

    private static func daemonUpToDate(daemonId: Data?) -> Bool {
        guard let daemonId else {
            os_log("Daemon unique ID is nil")
            return false
        }

        let bundleId = CSIdentification.getBundleRelativeUniqueId(
            relative: "Contents/Library/LaunchServices/" + BT_DAEMON_ID
        )
        guard let bundleId else {
            os_log("Bundle daemon unique ID is nil")
            return false
        }

        return bundleId == daemonId
    }
}
