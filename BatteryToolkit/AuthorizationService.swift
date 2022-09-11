import Foundation
import os.log
import BTPreprocessor

internal struct BTAuthorizationService {
    internal static func createEmptyAuthorization(reply: @escaping ((AuthorizationRef?) -> Void)) {
        let lConnect = NSXPCConnection(serviceName: BT_SERVICE_NAME)
        lConnect.remoteObjectInterface = NSXPCInterface(with: BTServiceCommProtocol.self)
        lConnect.resume()
        
        guard let service = lConnect.remoteObjectProxyWithErrorHandler({ error in
            os_log("XPC client remote object error: \(error)")
        }) as? BTServiceCommProtocol else {
            os_log("XPC client remote object is malfored")
            lConnect.invalidate()
            reply(nil)
            return
        }

        service.askAuthorization() { (authData) -> Void in
            lConnect.invalidate()

            guard let authData = authData, authData.count == kAuthorizationExternalFormLength else {
                reply(nil)
                return
            }

            var extAuth = AuthorizationExternalForm()
            memcpy(&extAuth, authData.bytes, Int(kAuthorizationExternalFormLength))

            var auth: AuthorizationRef? = nil
            let status = AuthorizationCreateFromExternalForm(&extAuth, &auth)
            guard status == errSecSuccess, let auth = auth else {
                reply(nil)
                return
            }

            reply(auth)
        }
    }
}
