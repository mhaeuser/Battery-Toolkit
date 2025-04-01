//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

internal extension BTDaemonManagement.Status {
    init(fromBool: Bool) {
        self = fromBool ? .enabled : .notRegistered
    }
}

internal extension BTDaemonManagement {
    @BTBackgroundActor
    enum Legacy {
        private static let daemonServicePlist = "\(BT_DAEMON_ID).plist"

        @available(macOS, deprecated: 13.0)
        static func register() async -> BTDaemonManagement.Status {
            os_log("Registering legacy helper")
            do {
                let authData = try await BTAppXPCClient.getAuthorization()
                try? await BTDaemonXPCClient.prepareUpdate()
                let simpleAuth = SimpleAuth.fromData(authData: authData)
                guard let simpleAuth else {
                    throw BTError.malformedData
                }
                
                var error: Unmanaged<CFError>?
                let success = SMJobBless(
                    kSMDomainSystemLaunchd,
                    BT_DAEMON_ID as CFString,
                    simpleAuth.authRef,
                    &error
                )

                BTDaemonXPCClient.finishUpdate()

                os_log(
                    "Legacy helper registering result: \(success), error: \(String(describing: error), privacy: .public))"
                )
                
                return BTDaemonManagement.Status(fromBool: success)
            } catch {
                BTDaemonXPCClient.finishUpdate()
                return .notRegistered
            }
        }

        static func unregister(simpleAuth: SimpleAuthRef) {
            os_log("Unregistering legacy helper")

            BTDaemonXPCClient.disconnectDaemon()
            //
            // The warning about SMJobRemove deprecation is misleading, as there
            // never was a replacement for this API. The only alternative, to
            // invoke launchctl, is being discouraged from.
            //
            var error: Unmanaged<CFError>? = nil
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                BT_DAEMON_ID as CFString,
                simpleAuth.authRef,
                true,
                &error
            )

            os_log(
                "Legacy helper unregistering result: \(success), error: \(String(describing: error), privacy: .public))"
            )
            //
            // Errors are not returned because the legacy helper PLIST has
            // already been deleted and next time we will not detect it anyway.
            //
        }

        static func unregisterCleanup() async throws {
            os_log("Unregistering legacy helper")

            do {
                let authData = try await BTAppXPCClient.getDaemonAuthorization()
                //
                // Legacy helpers require manual cleanup for removal.
                //
                try? await BTDaemonXPCClient
                    .removeLegacyHelperFiles(authData: authData)
                let simpleAuth = SimpleAuth.fromData(authData: authData)
                guard let simpleAuth else {
                    throw BTError.notAuthorized
                }
                
                self.unregister(simpleAuth: simpleAuth)
            } catch {
                throw BTError.notAuthorized
            }
        }
    }
}
