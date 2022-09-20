/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

// FIXME: Using 14.0 constants due to broken Ventura daemons

internal struct BTDaemonManagement {
    private static func daemonUpToDate(daemonId: NSData?) -> Bool {
        guard let daemonId = daemonId else {
            os_log("Daemon unique ID is nil")
            return false
        }

        let bundleId = CSIdentification.getBundleRelativeUniqueId(
            relative: "Contents/Library/LaunchServices/" + BT_DAEMON_NAME
            )
        guard let bundleId = bundleId else {
            os_log("Bundle daemon unique ID is nil")
            return false
        }

        return bundleId.isEqual(to: daemonId)
    }

    @MainActor internal static func start(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonXPCClient.getUniqueId { (daemonId) -> Void in
            guard daemonUpToDate(daemonId: daemonId) else {
                DispatchQueue.main.async {
                    if #available(macOS 14.0, *) {
                        BTDaemonManagementService.register(reply: reply)
                    } else {
                        BTDaemonManagementLegacy.register(reply: reply)
                    }
                }

                return
            }

            os_log("Daemon is up-to-date, skip install")
            reply(.enabled)
        }
    }
    
    internal static func approve() {
        if #available(macOS 14.0, *) {
            BTDaemonManagementService.approve()
        } else  {
            BTDaemonManagementLegacy.approve()
        }
    }
    
    @MainActor internal static func unregister(reply: @Sendable @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            BTDaemonManagementService.unregister(reply: reply)
        } else {
            BTDaemonManagementLegacy.unregister(reply: reply)
        }
    }
}
