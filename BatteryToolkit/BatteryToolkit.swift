import Foundation
import ServiceManagement

public struct BatteryToolkit {
    public static func startXpcClient() -> Bool {
        let result = BTHelperXPCClient.start()
        
        debugPrint("XPC client start: ", result)
        
        return result
    }
    
    public static func start() -> Bool {
        return BTAppXPCClient.installHelper()
    }
    
    public static func stop() {
        BTHelperXPCClient.stop()
    }
    
    public static func disableExternalPower() {
        BTHelperXPCClient.disableExternalPower()
    }

    public static func enableExternalPower() {
        BTHelperXPCClient.enableExternalPower()
    }

    public static func chargeToMaximum() {
        BTHelperXPCClient.chargeToMaximum()
    }

    public static func chargeToFull() {
        BTHelperXPCClient.chargeToFull()
    }

    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        BTHelperXPCClient.setChargeLimits(
            minCharge: minCharge,
            maxCharge: maxCharge
            )
    }
}
