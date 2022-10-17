//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
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
    enum Legacy {
        private static let daemonServicePlist = "\(BT_DAEMON_ID).plist"

        @available(macOS, deprecated: 13.0)
        @MainActor static func register(
            reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void
        ) {
            os_log("Registering legacy helper")

            BTAppXPCClient.getAuthorization { authData in
                assert(!Thread.isMainThread)

                let simpleAuth = SimpleAuth.fromData(authData: authData)
                guard let simpleAuth else {
                    reply(.notRegistered)
                    return
                }

                DispatchQueue.main.async {
                    BTDaemonXPCClient.prepareUpdate { _ in
                        var error: Unmanaged<CFError>?
                        let success = SMJobBless(
                            kSMDomainSystemLaunchd,
                            BT_DAEMON_ID as CFString,
                            simpleAuth.authRef,
                            &error
                        )

                        DispatchQueue.main.async {
                            BTDaemonXPCClient.finishUpdate()
                        }

                        os_log(
                            "Legacy helper registering result: \(success), error: \(String(describing: error))"
                        )

                        reply(
                            BTDaemonManagement.Status(fromBool: success)
                        )
                    }
                }
            }
        }

        static func upgrade() {
            //
            // There is no upgrade path to legacy daemons.
            //
            assertionFailure()
        }

        static func approve() {
            //
            // Approval is exclusive to SMAppService daemons.
            //
            assertionFailure()
        }

        static func unregister(simpleAuth: SimpleAuthRef) {
            os_log("Unregistering legacy helper")

            assert(!Thread.isMainThread)

            DispatchQueue.main.async {
                BTDaemonXPCClient.disconnectDaemon()
            }
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
                "Legacy helper unregistering result: \(success), error: \(String(describing: error))"
            )
            //
            // Errors are not returned because the legacy helper PLIST has
            // already been deleted and next time we will not detect it anyway.
            //
        }

        @MainActor static func unregisterCleanup(
            reply: @Sendable @escaping (BTError.RawValue) -> Void
        ) {
            os_log("Unregistering legacy helper")

            BTAppXPCClient.getDaemonAuthorization { authData in
                assert(!Thread.isMainThread)

                let simpleAuth = SimpleAuth.fromData(authData: authData)
                guard let simpleAuth else {
                    reply(BTError.notAuthorized.rawValue)
                    return
                }

                DispatchQueue.main.async {
                    //
                    // Legacy helpers require manual cleanup for removal.
                    //
                    // Force-unwrap is safe as simpleAuth would be nil if
                    // authData was nil.
                    //
                    BTDaemonXPCClient
                        .removeLegacyHelperFiles(authData: authData!) { error in
                            if error == BTError.success.rawValue {
                                unregister(simpleAuth: simpleAuth)
                            }

                            reply(error)
                        }
                }
            }
        }
    }
}
