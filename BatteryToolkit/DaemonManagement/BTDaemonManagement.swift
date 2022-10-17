//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

internal enum BTDaemonManagement {
    @MainActor static func start(
        reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
    ) {
        BTDaemonXPCClient.getUniqueId { daemonId in
            guard daemonUpToDate(daemonId: daemonId) else {
                DispatchQueue.main.async {
                    if #available(macOS 13.0, *) {
                        self.Service.register(reply: reply)
                    } else {
                        self.Legacy.register(reply: reply)
                    }
                }

                return
            }

            os_log("Daemon is up-to-date, skip install")
            reply(.enabled)
        }
    }

    @MainActor static func upgrade(
        reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
    ) {
        if #available(macOS 13.0, *) {
            self.Service.upgrade(reply: reply)
        } else {
            self.Legacy.upgrade()
        }
    }

    static func approve(
        timeout: UInt8,
        reply: @escaping @Sendable (Bool) -> Void
    ) {
        if #available(macOS 13.0, *) {
            self.Service.approve(timeout: timeout, reply: reply)
        } else {
            self.Legacy.approve()
        }
    }

    @MainActor static func remove(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        BTAppXPCClient.getDaemonAuthorization { authData in
            assert(!Thread.isMainThread)

            guard let authData else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            DispatchQueue.main.async {
                BTDaemonXPCClient.prepareDisable(authData: authData) { _ in
                    if #available(macOS 13.0, *) {
                        self.Service.unregister(reply: reply)
                    } else {
                        let simpleAuth = SimpleAuth.fromData(authData: authData)
                        guard let simpleAuth else {
                            reply(BTError.notAuthorized.rawValue)
                            return
                        }

                        self.Legacy.unregister(simpleAuth: simpleAuth)

                        reply(BTError.success.rawValue)
                    }
                }
            }
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
