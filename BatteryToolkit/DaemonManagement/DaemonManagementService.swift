/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import ServiceManagement
import BTPreprocessor

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

@available(macOS 13.0, *)
internal struct BTDaemonManagementService {
    private static let daemonServicePlist = "\(BT_DAEMON_NAME).plist"

    private static func registered(status: SMAppService.Status) -> Bool {
        return status != .notRegistered && status != .notFound
    }

    private static func registerSync(appService: SMAppService) {
        os_log("Registering daemon service")

        assert(!Thread.isMainThread)

        /*if registered(status: appService.status) {
         os_log("Daemon already registered: \(appService.status)")
         return
         }*/

        do {
            try appService.register()
        } catch {
            os_log("Daemon service registering failed, error: \(error), status: \(appService.status.rawValue)")
        }
    }

    private static func unregisterService(appService: SMAppService, reply: @Sendable @escaping (Bool) -> Void) {
        os_log("Unregistering daemon service")
        //
        // Any other status code makes unregister() loop indefinitely.
        //
        guard appService.status == .enabled else {
            DispatchQueue.global(qos: .userInitiated).async {
                reply(true)
            }

            return
        }

        appService.unregister() { (error) -> Void in
            if error != nil {
                os_log("Daemon service unregistering failed, error: \(error), status: \(appService.status.rawValue)")
            }

            reply(error == nil)
        }
    }

    @MainActor private static func unregisterLegacy(reply: @Sendable @escaping (Bool) -> Void) {
        os_log("Unregistering legacy helper via service")

        let legacyUrl = URL(fileURLWithPath: BTLegacyHelperInfo.legacyHelperPlist, isDirectory: false)
        let status    = SMAppService.statusForLegacyPlist(at: legacyUrl)
        guard registered(status: status) else {
            os_log("Legacy helper is not registered")
            reply(true)
            return
        }

        BTDaemonManagementLegacy.unregister(reply: reply)
    }

    private static func update(appService: SMAppService, reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Updating daemon service")

        unregisterService(appService: appService) { _ in
            assert(!Thread.isMainThread)

            for _ in 0...2 {
                registerSync(appService: appService)
                guard !registered(status: appService.status) else {
                    reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
                    return
                }

                // FIXME: Replace sleep() with DispatchQueue.asyncAfter()
                sleep(1)
            }

            reply(.notRegistered)
        }
    }

    @MainActor internal static func register(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Starting daemon service")

        unregisterLegacy { (success) -> Void in
            guard success else {
                reply(.notRegistered)
                return
            }

            let appService = SMAppService.daemon(plistName: BTDaemonManagementService.daemonServicePlist)
            update(appService: appService, reply: reply)
        }
    }

    internal static func approve() {
        SMAppService.openSystemSettingsLoginItems()
    }

    internal static func unregister(reply: @Sendable @escaping (Bool) -> Void) {
        let appService = SMAppService.daemon(plistName: BTDaemonManagementService.daemonServicePlist)
        unregisterService(appService: appService, reply: reply)
    }
}
