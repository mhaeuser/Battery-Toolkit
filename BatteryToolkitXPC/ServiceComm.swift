import Foundation
import ServiceManagement
import BTPreprocessor

public final class BTServiceComm: BTServiceCommProtocol {
    private static func askAuthorization() -> AuthorizationRef? {
        var auth: AuthorizationRef? = nil
        let status: OSStatus = AuthorizationCreate(nil, nil, [], &auth)
        if status != errAuthorizationSuccess {
            return nil
        }
        
        return auth
    }
    
    func installHelper() -> Void {
        guard let auth = BTServiceComm.askAuthorization() else {
            fatalError("Authorization not acquired.")
        }
        
        var error: Unmanaged<CFError>?
        let result = SMJobBless(
            kSMDomainSystemLaunchd,
            BT_HELPER_NAME as CFString,
            auth,
            &error
            )
        BTServiceXPCServer.submitInstallHelper(success: result)
    }
}
