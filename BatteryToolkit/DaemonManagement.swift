import Foundation
import os.log
import ServiceManagement
import BTPreprocessor

public struct BTDaemonManagement {
    private static let daemonServicePlist = "\(BT_DAEMON_NAME).plist"
    
    public enum Status: UInt8 {
        case notRegistered    = 0
        case enabled          = 1
        case requiresApproval = 2
        
        init(fromLegacySuccess: Bool) {
            self = fromLegacySuccess ? BTDaemonManagement.Status.enabled : BTDaemonManagement.Status.notRegistered
        }
        
        @available(macOS 13.0, *)
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

    @available(macOS, deprecated: 13.0)
    private static func registerLegacyHelper(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        BTAuthorizationService.createEmptyAuthorization() { (auth) -> Void in
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
            
            let status = AuthorizationFree(auth, [])
            if status != errSecSuccess {
                os_log("Freeing authorization error: \(status)")
            }
            
            reply(BTDaemonManagement.Status(fromLegacySuccess: success))
        }
    }
    
    @available(macOS, deprecated: 13.0)
    private static func startLegacyHelper(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        os_log("Starting legacy helper")
        // FIXME: Check daemon version and conditionally update
        BTDaemonManagement.registerLegacyHelper(reply: reply)
    }
    
    private static func unregisterLegacyHelper(reply: @escaping ((Bool) -> Void)) {
        os_log("Unregistering legacy helper")
        
        BTAuthorizationService.createEmptyAuthorization() { (auth) -> Void in
            guard let auth = auth else {
                reply(false)
                return
            }
            
            // FIXME: Client may not be started at this point
            BTHelperXPCClient.removeHelperFiles()

            var error: Unmanaged<CFError>? = nil
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                BT_LEGACY_HELPER_NAME as CFString,
                auth,
                true,
                &error
                )
            
            os_log("Legacy helper unregistering result: \(success), error: \(String(describing: error))")
            
            let status = AuthorizationFree(auth, [])
            if status != errSecSuccess {
                os_log("Freeing authorization error: \(status)")
            }
            
            reply(success)
        }
    }
    
    @available(macOS 13.0, *)
    private static func daemonServiceRegistered(status: SMAppService.Status) -> Bool {
        return status != SMAppService.Status.notRegistered &&
            status != SMAppService.Status.notFound
    }
    
    @available(macOS 13.0, *)
    private static func registerDaemonServiceSync(appService: SMAppService) {
        os_log("Registering daemon service")
        
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
    
    @available(macOS 13.0, *)
    private static func unregisterDaemonService(appService: SMAppService, reply: @escaping ((Bool) -> Void)) {
        os_log("Unregistering daemon service")
        //
        // Any other status code makes unregister() loop indefinitely.
        //
        if appService.status != SMAppService.Status.enabled {
            reply(true)
            return
        }
        
        appService.unregister() { (error) -> Void in
            if error != nil {
                os_log("Daemon service unregistering failed, error: \(error), status: \(appService.status.rawValue)")
            }
            
            reply(error == nil)
        }
    }
    
    @available(macOS 13.0, *)
    private static func unregisterLegacyHelperService(reply: @escaping ((Bool) -> Void)) {
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
    
    @available(macOS 13.0, *)
    private static func updateDaemonService(appService: SMAppService, reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        os_log("Updating daemon service")

        BTDaemonManagement.unregisterDaemonService(appService: appService) { _ in
            DispatchQueue.global(qos: .userInitiated).async {
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
    }
    
    @available(macOS 13.0, *)
    private static func startDaemonService(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        os_log("Starting daemon service")
        
        BTDaemonManagement.unregisterLegacyHelperService() { (success) -> Void in
            if !success {
                reply(BTDaemonManagement.Status.notRegistered)
                return
            }
            
            // FIXME: Check daemon version and conditionally update
            let appService = SMAppService.daemon(plistName: BTDaemonManagement.daemonServicePlist)
            BTDaemonManagement.updateDaemonService(appService: appService, reply: reply)
        }
    }
    
    public static func startDaemon(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        if #available(macOS 13.0, *) {
            BTDaemonManagement.startDaemonService(reply: reply)
        } else {
            BTDaemonManagement.startLegacyHelper(reply: reply)
        }
    }
    
    public static func approveDaemon() {
        if #available(macOS 13.0, *) {
            SMAppService.openSystemSettingsLoginItems()
        } else {
            assert(false)
        }
    }
    
    public static func unregisterDaemon(reply: @escaping ((Bool) -> Void)) {
        if #available(macOS 13.0, *) {
            let appService = SMAppService.daemon(plistName: BTDaemonManagement.daemonServicePlist)
            BTDaemonManagement.unregisterDaemonService(appService: appService, reply: reply)
        } else {
            BTDaemonManagement.unregisterLegacyHelper(reply: reply)
        }
    }
}
