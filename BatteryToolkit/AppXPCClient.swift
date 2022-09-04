import Foundation
import BTPreprocessor

public struct BTAppXPCClient {
    private static var connect: NSXPCConnection? = nil
    
    public static func installHelper() -> Bool {
        let lConnect = NSXPCConnection(serviceName: BT_SERVICE_NAME)

        lConnect.remoteObjectInterface = NSXPCInterface(with: BTServiceCommProtocol.self)
        
        lConnect.resume()
        
        guard let service = lConnect.remoteObjectProxyWithErrorHandler({ error in
            debugPrint("XPC client remote object error: ", error)
        }) as? BTServiceCommProtocol else {
            debugPrint("XPC client remote object is malfored")
            lConnect.invalidate()
            return false
        }
        
        connect = lConnect

        service.installHelper() { (success) -> Void in
            debugPrint("Helper install status: ", success)
            
            BTAppXPCClient.stop()
            
            if success {
                _ = BatteryToolkit.startXpcClient()
            }
        }
        
        return true
    }
    
    fileprivate static func stop() {
        assert(connect != nil)
        connect!.invalidate()
        connect = nil
    }
}
