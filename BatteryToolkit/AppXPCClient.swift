import Foundation
import BTPreprocessor

private final class BTAppComm: BTAppCommProtocol {
    func submitInstallHelper(success: Bool) -> Void {
        debugPrint("Helper install status: ", success)
        
        BTAppXPCClient.stop()
        
        if success {
            _ = BatteryToolkit.startXpcClient()
        }
    }
}

public struct BTAppXPCClient {
    private static var connect: NSXPCConnection? = nil
    
    public static func installHelper() -> Bool {
        let lConnect = NSXPCConnection(serviceName: BT_SERVICE_NAME)

        lConnect.exportedInterface = NSXPCInterface(with: BTAppCommProtocol.self)
        lConnect.exportedObject    = BTAppComm()

        lConnect.remoteObjectInterface = NSXPCInterface(with: BTServiceCommProtocol.self)
        
        lConnect.resume()
        
        guard let service = lConnect.remoteObjectProxyWithErrorHandler({ error in
            debugPrint("XPC client remote object error: ", error)
        }) as? BTServiceCommProtocol else {
            debugPrint("XPC client remote object is malfored")
            lConnect.suspend()
            lConnect.invalidate()
            return false
        }
        
        connect = lConnect

        service.installHelper()
        
        return true
    }
    
    fileprivate static func stop() {
        assert(connect != nil)
        connect!.invalidate()
        connect!.suspend()
        connect = nil
    }
}
