import Foundation

public struct BTPreferences {
    public static var minCharge: UInt8 = 70
    public static var maxCharge: UInt8 = 80

    private static let defaultsMinChargeName = "MinCharge"
    private static let defaultsMaxChargeName = "MaxCharge"
    
    private static func limitsValid(minCharge: Int, maxCharge: Int) -> Bool {
        if minCharge > maxCharge {
            return false
        }
        
        if minCharge < 10 || minCharge > 100 {
            return false
        }
        
        if maxCharge < 30 || maxCharge > 100 {
            return false
        }
        
        return true
    }
    
    private static func write() {
        assert(
            BTPreferences.limitsValid(
                minCharge: Int(BTPreferences.minCharge),
                maxCharge: Int(BTPreferences.maxCharge)
                )
            )

        UserDefaults.standard.set(
            BTPreferences.minCharge,
            forKey: BTPreferences.defaultsMinChargeName
            )
        UserDefaults.standard.set(
            BTPreferences.maxCharge,
            forKey: BTPreferences.defaultsMaxChargeName
            )
    }
    
    public static func read() {
        let minCharge = UserDefaults.standard.integer(
            forKey: BTPreferences.defaultsMinChargeName
            )
        let maxCharge = UserDefaults.standard.integer(
            forKey: BTPreferences.defaultsMaxChargeName
            )
        if !BTPreferences.limitsValid(minCharge: minCharge, maxCharge: maxCharge) {
            NSLog("Charge limits malformed, restore current values.")
            BTPreferences.write()
            return
        }
        
        BTPreferences.minCharge = UInt8(minCharge)
        BTPreferences.maxCharge = UInt8(maxCharge)
    }
    
    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        if !BTPreferences.limitsValid(minCharge: Int(minCharge), maxCharge: Int(maxCharge)) {
            NSLog("Client charge limits malformed, preserve current values.")
            return
        }
        
        BTPreferences.minCharge = minCharge
        BTPreferences.maxCharge = maxCharge
        
        BTPreferences.write()
        
        BTPowerEvents.preferencesChanged()
    }
}
