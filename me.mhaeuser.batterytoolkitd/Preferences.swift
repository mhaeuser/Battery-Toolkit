import Foundation
import os.log

public struct BTSettings {
    public private(set) static var minCharge: UInt8 = BTSettingsInfo.minChargeDefault
    public private(set) static var maxCharge: UInt8 = BTSettingsInfo.maxChargeDefault
    
    public private(set) static var adapterSleep = false

    private static let defaultsMinChargeName = "MinCharge"
    private static let defaultsMaxChargeName = "MaxCharge"
    private static let defaultsAdapterSleep  = "AdapterSleep"
    
    private static func limitsValid(minCharge: Int, maxCharge: Int) -> Bool {
        if minCharge > maxCharge {
            return false
        }
        
        if minCharge < BTSettingsInfo.minChargeMin || minCharge > 100 {
            return false
        }
        
        if maxCharge < BTSettingsInfo.maxChargeMin || maxCharge > 100 {
            return false
        }
        
        return true
    }
    
    private static func writeChargeLimits() {
        assert(
            BTSettings.limitsValid(
                minCharge: Int(BTSettings.minCharge),
                maxCharge: Int(BTSettings.maxCharge)
                )
            )

        UserDefaults.standard.set(
            BTSettings.minCharge,
            forKey: BTSettings.defaultsMinChargeName
            )
        UserDefaults.standard.set(
            BTSettings.maxCharge,
            forKey: BTSettings.defaultsMaxChargeName
            )
    }
    
    private static func writeAdapterSleep() {
        UserDefaults.standard.set(
            BTSettings.adapterSleep,
            forKey: BTSettings.defaultsAdapterSleep
            )
    }
    
    public static func read() {
        let minCharge = UserDefaults.standard.integer(
            forKey: BTSettings.defaultsMinChargeName
            )
        let maxCharge = UserDefaults.standard.integer(
            forKey: BTSettings.defaultsMaxChargeName
            )
        if !BTSettings.limitsValid(minCharge: minCharge, maxCharge: maxCharge) {
            os_log("Charge limits malformed, restore current values")
            BTSettings.writeChargeLimits()
            return
        }
        
        BTSettings.minCharge    = UInt8(minCharge)
        BTSettings.maxCharge    = UInt8(maxCharge)
        BTSettings.adapterSleep = UserDefaults.standard.bool(
            forKey: BTSettings.defaultsAdapterSleep
            )
    }
    
    public static func setChargeLimits(minCharge: UInt8, maxCharge: UInt8) {
        if !BTSettings.limitsValid(minCharge: Int(minCharge), maxCharge: Int(maxCharge)) {
            os_log("Client charge limits malformed, preserve current values")
            return
        }
        
        BTSettings.minCharge = minCharge
        BTSettings.maxCharge = maxCharge
        
        BTSettings.writeChargeLimits()
        
        BTPowerEvents.settingsChanged()
    }
    
    public static func setAdapterSleep(enabled: Bool) {
        if BTSettings.adapterSleep == enabled {
            return
        }

        BTSettings.adapterSleep = enabled
        
        BTSettings.writeAdapterSleep()
        
        BTPowerState.adapterSleepPreferenceToggled()
    }
}
