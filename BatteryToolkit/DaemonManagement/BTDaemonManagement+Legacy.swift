/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import ServiceManagement
import BTPreprocessor

internal extension BTDaemonManagement.Status {
    init(fromLegacySuccess: Bool) {
        self = fromLegacySuccess ? .enabled : .notRegistered
    }
}

internal extension BTDaemonManagement {
    struct Legacy {
        private static let daemonServicePlist = "\(BT_DAEMON_NAME).plist"

        @available(macOS, deprecated: 13.0)
        @MainActor internal static func register(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
            os_log("Registering legacy helper")

            BTAuthorizationService.empty() { (auth) -> Void in
                assert(!Thread.isMainThread)

                guard let auth = auth else {
                    reply(.notRegistered)
                    return
                }

                DispatchQueue.main.async {
                    BTDaemonXPCClient.prepareUpdate()

                    DispatchQueue.global(qos: .userInitiated).async {
                        var error: Unmanaged<CFError>?
                        let success = SMJobBless(
                            kSMDomainSystemLaunchd,
                            BT_DAEMON_NAME as CFString,
                            auth,
                            &error
                            )

                        DispatchQueue.main.async {
                            BTDaemonXPCClient.finishUpdate()
                        }

                        os_log("Legacy helper registering result: \(success), error: \(String(describing: error))")

                        let status = AuthorizationFree(auth, [.destroyRights])
                        if status != errSecSuccess {
                            os_log("Freeing authorization error: \(status)")
                        }

                        reply(BTDaemonManagement.Status(fromLegacySuccess: success))
                    }
                }
            }
        }

        internal static func upgrade() {
            assert(false)
        }

        internal static func approve() {
            assert(false)
        }

        internal static func unregister(authRef: AuthorizationRef) {
            os_log("Unregistering legacy helper")

            assert(!Thread.isMainThread)

            DispatchQueue.main.async {
                BTDaemonXPCClient.disconnectDaemon()
            }

            var error: Unmanaged<CFError>? = nil
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                BT_DAEMON_NAME as CFString,
                authRef,
                true,
                &error
                )

            os_log(
                "Legacy helper unregistering result: \(success), error: \(String(describing: error))"
                )
            //
            // Errors are not returned because the legacy helper PLIST has already
            // been deleted and next time we will not detect it anyway.
            //
        }

        @MainActor internal static func unregisterCleanup(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
            os_log("Unregistering legacy helper")

            BTAuthorizationService.daemonManagement() { auth in
                assert(!Thread.isMainThread)

                guard let auth = auth else {
                    reply(BTError.notAuthorized.rawValue)
                    return
                }

                DispatchQueue.main.async {
                    BTDaemonXPCClient.removeLegacyHelperFiles(authRef: auth) { error in
                        if error == BTError.success.rawValue {
                            unregister(authRef: auth)
                        }

                        let status = AuthorizationFree(auth, [.destroyRights])
                        if status != errSecSuccess {
                            os_log("Freeing authorization error: \(status)")
                        }

                        reply(error)
                    }
                }
            }
        }
    }
}
