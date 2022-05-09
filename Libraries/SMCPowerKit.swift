private struct SMCPowerKitKeys {
    fileprivate static let CH0C = SMCKitKey("C", "H", "0", "C")
    fileprivate static let CH0J = SMCKitKey("C", "H", "0", "J")
}

public struct SMCKitKeyInfo {
    let key: SMCId;
    let info: SMCKitKeyInfoData
}

public struct SMCPowerKit {
    private static let keys =
        [
            SMCKitKeyInfo(
                key: SMCPowerKitKeys.CH0C,
                info: SMCKitKeyInfoData(
                    dataSize: 1,
                    dataType: SMCKitType.hex,
                    dataAttributes: 0xD4
                    )
                ),
            SMCKitKeyInfo(
                key: SMCPowerKitKeys.CH0J,
                info: SMCKitKeyInfoData(
                    dataSize: 1,
                    dataType: SMCKitType.ui8,
                    dataAttributes: 0xD4
                    )
                )
        ]

    public static func supported() -> Bool {
        for keyInfo in SMCPowerKit.keys {
            do {
                let info = try SMCKit.GetKeyInfo(key: keyInfo.key)
                if keyInfo.info != info {
                    return false
                }
            } catch {
                return false
            }
        }
        
        return true
    }

    public static func enableCharging() -> Bool {
        do {
            try SMCKit.WriteKeyUI8(key: SMCPowerKitKeys.CH0C, value: 0x00)
            return true
        } catch {
            return false
        }
    }

    public static func disableCharging() -> Bool {
        do {
            try SMCKit.WriteKeyUI8(key: SMCPowerKitKeys.CH0C, value: 0x01)
            return true
        } catch {
            return false
        }
    }
    
    public static func isChargingEnabled() -> Bool {
        do {
            let value = try SMCKit.ReadKeyUI8(key: SMCPowerKitKeys.CH0C)
            return value == 0x00
        } catch {
            return false
        }
    }
    
    public static func enableExternalPower() -> Bool {
        do {
            try SMCKit.WriteKeyUI8(key: SMCPowerKitKeys.CH0J, value: 0x00)
            return true
        } catch {
            return false
        }
    }
    
    public static func disableExternalPower() -> Bool {
        do {
            try SMCKit.WriteKeyUI8(key: SMCPowerKitKeys.CH0J, value: 0x20)
            return true
        } catch {
            return false
        }
    }
    
    public static func isExternalPowerEnabled() -> Bool {
        do {
            let value = try SMCKit.ReadKeyUI8(key: SMCPowerKitKeys.CH0J)
            return value == 0x00
        } catch {
            return false
        }
    }
}
