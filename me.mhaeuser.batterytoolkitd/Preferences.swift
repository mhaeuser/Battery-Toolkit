import Foundation

public struct BTPreferences {
    public private(set) static var minCharge: UInt8 = BTPreferencesInfo.minChargeDefault
    public private(set) static var maxCharge: UInt8 = BTPreferencesInfo.maxChargeDefault
    
    public private(set) static var adapterSleep = false

    private static let defaultsMinChargeName = "MinCharge"
    private static let defaultsMaxChargeName = "MaxCharge"
    private static let defaultsAdapterSleep  = "AdapterSleep"
    
    private static func limitsValid(minCharge: Int, maxCharge: Int) -> Bool {
        if minCharge > maxCharge {
            return false
        }
        
        if minCharge < BTPreferencesInfo.minChargeMin || minCharge > 100 {
            return false
        }
        
        if maxCharge < BTPreferencesInfo.maxChargeMin || maxCharge > 100 {
            return false
        }
        
        return true
    }
    
    private static func writeChargeLimits() {
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
    
    private static func writeAdapterSleep() {
        UserDefaults.standard.set(
            BTPreferences.adapterSleep,
            forKey: BTPreferences.defaultsAdapterSleep
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
            NSLog("Charge limits malformed, restore current values")
            BTPreferences.writeChargeLimits()
            return
        }
        
        BTPreferences.minCharge    = UInt8(minCharge)
        BTPreferences.maxCharge    = UInt8(maxCharge)
        BTPreferences.adapterSleep = UserDefaults.standard.bool(
            forKey: BTPreferences.defaultsAdapterSleep
            )
    }
    
    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        if !BTPreferences.limitsValid(minCharge: Int(minCharge), maxCharge: Int(maxCharge)) {
            NSLog("Client charge limits malformed, preserve current values")
            return
        }
        
        BTPreferences.minCharge = minCharge
        BTPreferences.maxCharge = maxCharge
        
        BTPreferences.writeChargeLimits()
        
        BTPowerEvents.preferencesChanged()
    }
    
    public static func setAdapterSleep(enabled: Bool) {
        if BTPreferences.adapterSleep == enabled {
            return
        }

        BTPreferences.adapterSleep = enabled
        
        BTPreferences.writeAdapterSleep()
        
        BTPowerState.adapterSleepPreferenceToggled()
    }
}
