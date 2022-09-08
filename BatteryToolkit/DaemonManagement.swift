import Foundation
import ServiceManagement
import BTPreprocessor

public struct BTDaemonManagement {
    private static let daemonServicePlist = "me.mhaeuser.batterytoolkitd.plist"
    
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
                case SMAppService.Status.notRegistered:
                    self = BTDaemonManagement.Status.notRegistered
                    
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
                BT_DAEMON_NAME as CFString,
                auth,
                &error
                )
            
            // FIXME: Log error
            _ = AuthorizationFree(auth, [])
            
            debugPrint("Legacy helper registering result: \(success)")
            
            reply(BTDaemonManagement.Status(fromLegacySuccess: success))
        }
    }
    
    @available(macOS, deprecated: 13.0)
    private static func startLegacyHelper(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        debugPrint("Starting legacy helper")
        // FIXME: Check daemon version and conditionally update
        BTDaemonManagement.registerLegacyHelper(reply: reply)
    }
    
    private static func unregisterLegacyHelper(reply: @escaping ((Bool) -> Void)) {
        debugPrint("Unregistering legacy helper")
        
        BTAuthorizationService.createEmptyAuthorization() { (auth) -> Void in
            guard let auth = auth else {
                reply(false)
                return
            }
            
            // FIXME: Client is not started at this point
            BTHelperXPCClient.removeHelperFiles()

            var error: Unmanaged<CFError>?
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                BT_DAEMON_NAME as CFString,
                auth,
                true,
                &error
                )
            
            debugPrint("Legacy helper unregistering result: \(success)")
            
            let status = AuthorizationFree(auth, [])
            if status != errSecSuccess {
                debugPrint("Freeing authorization status: \(status)")
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
        debugPrint("Registering daemon service")
        
        if BTDaemonManagement.daemonServiceRegistered(status: appService.status) {
            debugPrint("Daemon already registered: \(appService.status)")
            return
        }

        do {
            try appService.register()
        } catch {
            debugPrint("Daemon service registering failed, error: \(error), status: \(appService.status)")
        }
    }

    @available(macOS 13.0, *)
    private static func registerDaemonService(appService: SMAppService, reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        BTDaemonManagement.registerDaemonServiceSync(appService: appService)
        reply(BTDaemonManagement.Status.init(fromSMStatus: appService.status))
    }
    
    @available(macOS 13.0, *)
    private static func unregisterDaemonService(appService: SMAppService, reply: @escaping ((Bool) -> Void)) {
        debugPrint("Unregistering daemon service")
        
        if !BTDaemonManagement.daemonServiceRegistered(status: appService.status) {
            reply(true)
            return
        }
        
        appService.unregister() { (error) -> Void in
            guard let error = error else {
                reply(true)
                return
            }
            
            debugPrint("Daemon service unregistering failed, error: \(error), status: \(appService.status)")
        }
    }
    
    @available(macOS 13.0, *)
    private static func unregisterLegacyHelperService() {
        debugPrint("Unregistering legacy helper via service")
        
        // FIXME: Share path with daemon
        guard let legacyUrl = URL(string: "file://" + BTLegacyHelperInfo.legacyHelperPlist) else {
            print("URL could not be formed")
            return
        }

        let status = SMAppService.statusForLegacyPlist(at: legacyUrl)
        if !BTDaemonManagement.daemonServiceRegistered(status: status) {
            return
        }
        
        BTDaemonManagement.unregisterLegacyHelper() { _ -> Void in
            
        }
    }
    
    @available(macOS 13.0, *)
    private static func updateDaemonService(appService: SMAppService, reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        debugPrint("Updating daemon service")
        //
        // Any other status code makes unregister() loop indefinitely.
        //
        if appService.status != SMAppService.Status.enabled {
            BTDaemonManagement.registerDaemonServiceSync(appService: appService)
            reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
            return
        }

        appService.unregister() { _ in
            for _ in 0...2 {
                BTDaemonManagement.registerDaemonServiceSync(appService: appService)
                if BTDaemonManagement.daemonServiceRegistered(status: appService.status) {
                    reply(BTDaemonManagement.Status(fromSMStatus: appService.status))
                    return
                }
                
                sleep(1)
            }
            
            reply(BTDaemonManagement.Status.notRegistered)
        }
    }
    
    @available(macOS 13.0, *)
    private static func startDaemonService(reply: @escaping ((BTDaemonManagement.Status) -> Void)) {
        debugPrint("Starting daemon service")
        
        BTDaemonManagement.unregisterLegacyHelperService()

        // FIXME: Check daemon version and conditionally update
        let appService = SMAppService.daemon(plistName: BTDaemonManagement.daemonServicePlist)
        BTDaemonManagement.updateDaemonService(appService: appService, reply: reply)
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
