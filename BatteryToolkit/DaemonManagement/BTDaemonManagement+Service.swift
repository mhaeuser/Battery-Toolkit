//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
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
        private static let daemonServicePlist = "\(BT_DAEMON_NAME).plist"

        private static func registered(status: SMAppService.Status) -> Bool {
            return status != .notRegistered && status != .notFound
        }

        private static func registerSync(appService: SMAppService) {
            os_log("Registering daemon service")

            assert(!Thread.isMainThread)

            do {
                try appService.register()
            } catch {
                os_log(
                    "Daemon service registering failed, error: \(error), status: \(appService.status.rawValue)"
                )
            }
        }

        internal static func unregister(
            reply: @Sendable @escaping (BTError.RawValue) -> Void
        ) {
            os_log("Unregistering daemon service")
            //
            // Any other status code makes unregister() loop indefinitely.
            //
            let appService = SMAppService.daemon(
                plistName: BTDaemonManagement.Service.daemonServicePlist
            )
            guard appService.status == .enabled else {
                DispatchQueue.global(qos: .userInitiated).async {
                    reply(BTError.success.rawValue)
                }

                return
            }

            DispatchQueue.main.async {
                BTDaemonXPCClient.disconnectDaemon()
            }

            appService.unregister { error in
                if error != nil {
                    os_log(
                        "Daemon service unregistering failed, error: \(error), status: \(appService.status.rawValue)"
                    )
                }

                reply(BTError(fromBool: error == nil).rawValue)
            }
        }

        private static func forceRegister(
            run: UInt8,
            reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
        ) {
            guard run < 6 else {
                DispatchQueue.main.async {
                    BTDaemonXPCClient.finishUpdate()
                }

                reply(.notRegistered)
                return
            }

            assert(!Thread.isMainThread)

            let appService = SMAppService.daemon(
                plistName: BTDaemonManagement.Service.daemonServicePlist
            )
            self.registerSync(appService: appService)
            guard self.registered(status: appService.status) else {
                DispatchQueue.global(qos: .userInitiated)
                    .asyncAfter(deadline: .now() + 0.5) {
                        forceRegister(run: run + 1, reply: reply)
                    }

                return
            }

            DispatchQueue.main.async {
                BTDaemonXPCClient.finishUpdate()
            }

            reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
        }

        @MainActor private static func update(
            reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
        ) {
            os_log("Updating daemon service")

            BTDaemonXPCClient.prepareUpdate { _ in
                DispatchQueue.main.async {
                    self.unregister { _ in
                        forceRegister(run: 0, reply: reply)
                    }
                }
            }
        }

        private static func awaitUnregister(
            run: UInt8,
            reply: @Sendable @escaping (Bool) -> Void
        ) {
            let appService = SMAppService.daemon(
                plistName: BTDaemonManagement.Service.daemonServicePlist
            )
            guard !self.registered(status: appService.status) else {
                guard run < 24 else {
                    reply(false)
                    return
                }

                DispatchQueue.global(qos: .userInitiated)
                    .asyncAfter(deadline: .now() + 5) {
                        awaitUnregister(run: run + 1, reply: reply)
                    }

                return
            }

            reply(true)
        }

        private static func awaitApproval(
            run: UInt8,
            timeout: UInt8,
            reply: @escaping @Sendable (Bool) -> Void
        ) {
            let appService = SMAppService.daemon(
                plistName: BTDaemonManagement.Service.daemonServicePlist
            )
            guard appService.status == .enabled else {
                guard run < timeout else {
                    reply(false)
                    return
                }

                DispatchQueue.global(qos: .userInitiated)
                    .asyncAfter(deadline: .now() + 1) {
                        awaitApproval(
                            run: run + 1,
                            timeout: timeout,
                            reply: reply
                        )
                    }

                return
            }

            reply(true)
        }

        @MainActor internal static func register(
            reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
        ) {
            os_log("Starting daemon service")

            let status = SMAppService.statusForLegacyPlist(
                at: BTLegacyHelperInfo.legacyHelperPlist
            )
            guard self.registered(status: status) else {
                self.update(reply: reply)
                return
            }

            os_log("Legacy helper registered")
            reply(.requiresUpgrade)
        }

        @MainActor internal static func upgrade(
            reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
        ) {
            os_log("Upgrading daemon service")

            BTDaemonManagement.Legacy.unregisterCleanup { error in
                guard error == BTError.success.rawValue else {
                    reply(.notRegistered)
                    return
                }

                awaitUnregister(run: 0) { success in
                    guard success else {
                        reply(.notRegistered)
                        return
                    }

                    DispatchQueue.main.async {
                        update(reply: reply)
                    }
                }
            }
        }

        internal static func approve(
            timeout: UInt8,
            reply: @escaping @Sendable (Bool) -> Void
        ) {
            SMAppService.openSystemSettingsLoginItems()
            self.awaitApproval(run: 0, timeout: timeout, reply: reply)
        }
    }
}
