//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

@available(macOS 13.0, *)
internal extension BTDaemonManagement.Status {
    init(fromSMStatus: SMAppService.Status) {
        switch fromSMStatus {
        case .enabled:
            self = .enabled

        case .requiresApproval:
            self = .requiresApproval

        default:
            self = .notRegistered
        }
    }
}

internal extension BTDaemonManagement {
    @available(macOS 13.0, *)
    enum Service {
        private static let daemonServicePlist = "\(BT_DAEMON_ID).plist"

        @MainActor static func register() async -> BTDaemonManagement.Status {
            os_log("Starting daemon service")

            let status = SMAppService.statusForLegacyPlist(
                at: BTLegacyHelperInfo.legacyHelperPlist
            )
            guard self.registered(status: status) else {
                return await self.update()
            }

            os_log("Legacy helper registered")
            return .requiresUpgrade
        }

        @MainActor static func upgrade() async -> BTDaemonManagement.Status {
            os_log("Upgrading daemon service")

            do {
                try await BTDaemonManagement.Legacy.unregisterCleanup()
                try await self.awaitUnregister()
                return await self.update()
            } catch {
                return .notRegistered
            }
        }

        static func approve(timeout: UInt8) async throws {
            SMAppService.openSystemSettingsLoginItems()
            try await self.awaitApproval(timeout: timeout)
        }

        @MainActor static func unregister() throws {
            os_log("Unregistering daemon service")
            //
            // Any other status code makes unregister() loop indefinitely.
            //
            let appService = SMAppService.daemon(
                plistName: self.daemonServicePlist
            )
            guard appService.status == .enabled else {
                return
            }

            BTDaemonXPCClient.disconnectDaemon()
            
            do {
                try appService.unregister()
            } catch {
                os_log(
                    "Daemon service unregistering failed, error: \(error), status: \(appService.status.rawValue)"
                )
                
                throw BTError.unknown
            }
        }

        private static func registered(status: SMAppService.Status) -> Bool {
            return status != .notRegistered && status != .notFound
        }

        private static func registerSync(appService: SMAppService) {
            os_log("Registering daemon service")

            do {
                try appService.register()
            } catch {
                os_log(
                    "Daemon service registering failed, error: \(error), status: \(appService.status.rawValue)"
                )
            }
        }

        @MainActor private static func forceRegister() async -> BTDaemonManagement.Status {
            //
            // After unregistering(e.g., to update the daemon), re-registering
            // may fail for a short amount of time.
            //
            for _ in 0...5 {
                let appService = SMAppService.daemon(
                    plistName: self.daemonServicePlist
                )
                self.registerSync(appService: appService)
                if self.registered(status: appService.status) {
                    BTDaemonXPCClient.finishUpdate()

                    return BTDaemonManagement.Status(fromSMStatus: appService.status)
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000)
            }

            BTDaemonXPCClient.finishUpdate()
            
            return .notRegistered
        }

        @MainActor private static func update() async -> BTDaemonManagement.Status {
            os_log("Updating daemon service")

            try? await BTDaemonXPCClient.prepareUpdate()
            try? self.unregister()
            try? await self.awaitUnregister()
            return await self.forceRegister()
        }

        private static func awaitUnregister() async throws {
            //
            // After unregistering the legacy helper, it may take one to two
            // minutes for the job to actually report as unregistered.
            //
            let appService = SMAppService.daemon(
                plistName: self.daemonServicePlist
            )
            for _ in 0...23 {
                if !self.registered(status: appService.status) {
                    return
                }
                
                
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }

            throw BTError.unknown
        }

        private static func awaitApproval(timeout: UInt8) async throws {
            let appService = SMAppService.daemon(
                plistName: self.daemonServicePlist
            )
            for _ in 0...timeout {
                if appService.status == .enabled {
                    return
                }
                
                
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
            
            throw BTError.unknown
        }
    }
}
