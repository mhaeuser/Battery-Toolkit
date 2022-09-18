/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import ServiceManagement
import BTPreprocessor

// FIXME: Using 14.0 constants due to broken Ventura daemons

extension BTDaemonManagement.Status {
    init(fromLegacySuccess: Bool) {
        self = fromLegacySuccess ? BTDaemonManagement.Status.enabled : BTDaemonManagement.Status.notRegistered
    }

    @available(macOS 14.0, *)
    init(fromSMStatus: SMAppService.Status) {
        switch fromSMStatus {
            case SMAppService.Status.enabled:
                self = BTDaemonManagement.Status.enabled

            case SMAppService.Status.requiresApproval:
                self = BTDaemonManagement.Status.requiresApproval

            default:
                self = BTDaemonManagement.Status.notRegistered
        }
    }
}

internal struct BTDaemonManagement {
    private static let daemonServicePlist = "\(BT_DAEMON_NAME).plist"

    @available(macOS, deprecated: 14.0)
    @MainActor private static func registerLegacyHelper(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Registering legacy helper")

        BTAuthorizationService.createEmptyAuthorization() { (auth) -> Void in
            assert(!Thread.isMainThread)

            guard let auth = auth else {
                reply(BTDaemonManagement.Status.notRegistered)
                return
            }

            var error: Unmanaged<CFError>?
            let success = SMJobBless(
                kSMDomainSystemLaunchd,
                BT_LEGACY_HELPER_NAME as CFString,
                auth,
                &error
                )

            os_log("Legacy helper registering result: \(success), error: \(String(describing: error))")
            
            let status = AuthorizationFree(auth, [.destroyRights])
            if status != errSecSuccess {
                os_log("Freeing authorization error: \(status)")
            }
            
            reply(BTDaemonManagement.Status(fromLegacySuccess: success))
        }
    }
    
    @MainActor private static func unregisterLegacyHelper(reply: @Sendable @escaping (Bool) -> Void) {
        os_log("Unregistering legacy helper")
        
        BTAuthorizationService.createEmptyAuthorization() { (auth) -> Void in
            assert(!Thread.isMainThread)

            guard let auth = auth else {
                reply(false)
                return
            }

            DispatchQueue.main.async {
                BTDaemonXPCClient.removeLegacyHelperFiles()
            }

            var error: Unmanaged<CFError>? = nil
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                BT_LEGACY_HELPER_NAME as CFString,
                auth,
                true,
                &error
                )
            
            os_log("Legacy helper unregistering result: \(success), error: \(String(describing: error))")
            
            let status = AuthorizationFree(auth, [.destroyRights])
            if status != errSecSuccess {
                os_log("Freeing authorization error: \(status)")
            }
            
            reply(success)
        }
    }
    
    @available(macOS 14.0, *)
    private static func daemonServiceRegistered(status: SMAppService.Status) -> Bool {
        return status != SMAppService.Status.notRegistered &&
            status != SMAppService.Status.notFound
    }
    
    @available(macOS 14.0, *)
    private static func registerDaemonServiceSync(appService: SMAppService) {
        os_log("Registering daemon service")

        assert(!Thread.isMainThread)
        
        /*if BTDaemonManagement.daemonServiceRegistered(status: appService.status) {
            os_log("Daemon already registered: \(appService.status)")
            return
        }*/

        do {
            try appService.register()
        } catch {
            os_log("Daemon service registering failed, error: \(error), status: \(appService.status.rawValue)")
        }
    }
    
    @available(macOS 14.0, *)
    private static func unregisterDaemonService(appService: SMAppService, reply: @Sendable @escaping (Bool) -> Void) {
        os_log("Unregistering daemon service")
        //
        // Any other status code makes unregister() loop indefinitely.
        //
        if appService.status != SMAppService.Status.enabled {
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
    
    @available(macOS 14.0, *)
    @MainActor private static func unregisterLegacyHelperService(reply: @Sendable @escaping (Bool) -> Void) {
        os_log("Unregistering legacy helper via service")

        let legacyUrl = URL(fileURLWithPath: BTLegacyHelperInfo.legacyHelperPlist, isDirectory: false)
        let status    = SMAppService.statusForLegacyPlist(at: legacyUrl)
        if !BTDaemonManagement.daemonServiceRegistered(status: status) {
            os_log("Legacy helper is not registered")
            reply(true)
            return
        }
        
        BTDaemonManagement.unregisterLegacyHelper(reply: reply)
    }
    
    @available(macOS 14.0, *)
    private static func updateDaemonService(appService: SMAppService, reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Updating daemon service")

        BTDaemonManagement.unregisterDaemonService(appService: appService) { _ in
            assert(!Thread.isMainThread)

            for _ in 0...2 {
                BTDaemonManagement.registerDaemonServiceSync(appService: appService)
                if BTDaemonManagement.daemonServiceRegistered(status: appService.status) {
                    reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
                    return
                }

                // FIXME: Replace sleep() with DispatchQueue.asyncAfter()
                sleep(1)
            }

            reply(BTDaemonManagement.Status.notRegistered)
        }
    }
    
    @available(macOS 14.0, *)
    @MainActor private static func registerDaemonService(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        os_log("Starting daemon service")
        
        BTDaemonManagement.unregisterLegacyHelperService() { (success) -> Void in
            if !success {
                reply(BTDaemonManagement.Status.notRegistered)
                return
            }

            let appService = SMAppService.daemon(plistName: BTDaemonManagement.daemonServicePlist)
            BTDaemonManagement.updateDaemonService(appService: appService, reply: reply)
        }
    }

    private static func daemonUpToDate(daemonId: NSData?) -> Bool {
        guard let daemonId = daemonId else {
            os_log("Daemon unique ID is nil")
            return false
        }

        let bundleId = CSIdentification.getBundleRelativeUniqueId(
            relative: "Contents/Library/LaunchServices/me.mhaeuser.batterytoolkitd"
            )
        guard let bundleId = bundleId else {
            os_log("Bundle daemon unique ID is nil")
            return false
        }

        return bundleId.isEqual(to: daemonId)
    }
    
    @MainActor internal static func startDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        BTDaemonXPCClient.getUniqueId { (daemonId) -> Void in
            if !BTDaemonManagement.daemonUpToDate(daemonId: daemonId) {
                DispatchQueue.main.async {
                    if #available(macOS 14.0, *) {
                        BTDaemonManagement.registerDaemonService(reply: reply)
                    } else {
                        BTDaemonManagement.registerLegacyHelper(reply: reply)
                    }
                }
            } else {
                os_log("The daemon is unchanged, skip install")
                reply(BTDaemonManagement.Status.enabled)
            }
        }
    }
    
    internal static func approveDaemon() {
        if #available(macOS 14.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        } else {
            assert(false)
        }
    }
    
    @MainActor internal static func unregisterDaemon(reply: @Sendable @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            let appService = SMAppService.daemon(plistName: BTDaemonManagement.daemonServicePlist)
            BTDaemonManagement.unregisterDaemonService(appService: appService, reply: reply)
        } else {
            BTDaemonManagement.unregisterLegacyHelper(reply: reply)
        }
    }
}
