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

    private static func unregisterService(reply: @Sendable @escaping (Bool) -> Void) {
        os_log("Unregistering daemon service")
        //
        // Any other status code makes unregister() loop indefinitely.
        //
        let appService = SMAppService.daemon(plistName: BTDaemonManagementService.daemonServicePlist)
        guard appService.status == .enabled else {
            DispatchQueue.global(qos: .userInitiated).async {
                reply(true)
            }

            return
        }

        DispatchQueue.main.async {
            BTDaemonXPCClient.disconnectDaemon()
        }

        appService.unregister() { (error) -> Void in
            if error != nil {
                os_log("Daemon service unregistering failed, error: \(error), status: \(appService.status.rawValue)")
            }

            reply(error == nil)
        }
    }

    private static func forceRegister(run: UInt8, reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        guard run < 6 else {
            reply(.notRegistered)
            return
        }

        assert(!Thread.isMainThread)

        let appService = SMAppService.daemon(plistName: BTDaemonManagementService.daemonServicePlist)
        registerSync(appService: appService)
        guard registered(status: appService.status) else {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                forceRegister(run: run + 1, reply: reply)
            }
            return
        }

        reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
    }

    private static func update(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Updating daemon service")

        unregisterService { _ in
            forceRegister(run: 0, reply: reply)
        }
    }

    private static func awaitUnregister(run: UInt8, reply: @Sendable @escaping (Bool) -> Void) {
        let appService = SMAppService.daemon(plistName: BTDaemonManagementService.daemonServicePlist)
        guard !registered(status: appService.status) else {
            guard run < 18 else {
                reply(false)
                return
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 5) {
                awaitUnregister(run: run + 1, reply: reply)
            }

            return
        }

        reply(true)
    }

    private static func awaitApproval(run: UInt8, timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {
        let appService = SMAppService.daemon(plistName: BTDaemonManagementService.daemonServicePlist)
        guard appService.status == .enabled else {
            guard run < timeout else {
                reply(false)
                return
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
                awaitApproval(run: run + 1, timeout: timeout, reply: reply)
            }

            return
        }

        reply(true)
    }

    @MainActor internal static func register(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Starting daemon service")

        let status = SMAppService.statusForLegacyPlist(
            at: BTLegacyHelperInfo.legacyHelperPlist
            )
        guard registered(status: status) else {
            os_log("Legacy helper is not registered")
            update(reply: reply)
            return
        }

        reply(.requiresUpgrade)
    }

    @MainActor internal static func upgrade(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonManagementLegacy.unregister() { success in
            guard success else {
                reply(.notRegistered)
                return
            }

            awaitUnregister(run: 0) { success in
                guard success else {
                    reply(.notRegistered)
                    return
                }

                update(reply: reply)
            }
        }
    }

    internal static func approve(timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {
        SMAppService.openSystemSettingsLoginItems()
        awaitApproval(run: 0, timeout: timeout, reply: reply)
    }

    internal static func unregister(reply: @Sendable @escaping (Bool) -> Void) {
        unregisterService(reply: reply)
    }
}
