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

    private static func forceRegister(appService: SMAppService, run: UInt8, reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        guard run < 6 else {
            reply(.notRegistered)
            return
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            registerSync(appService: appService)
            guard registered(status: appService.status) else {
                forceRegister(appService: appService, run: run + 1, reply: reply)
                return
            }

            reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
        }
    }

    private static func update(appService: SMAppService, reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Updating daemon service")

        unregisterService(appService: appService) { _ in
            assert(!Thread.isMainThread)

            forceRegister(appService: appService, run: 0, reply: reply)
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
