//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCKit {
    @MainActor
    enum Power {
        private enum Keys {
            fileprivate static let CH0C = SMCKitKey("C", "H", "0", "C")
            fileprivate static let CH0J = SMCKitKey("C", "H", "0", "J")
        }

        private static let keys =
            [
                SMCKitKeyInfo(
                    key: SMCKit.Power.Keys.CH0C,
                    info: SMCKitKeyInfoData(
                        dataSize: 1,
                        dataType: SMCKitType.hex,
                        dataAttributes: 0xD4
                    )
                ),
                SMCKitKeyInfo(
                    key: SMCKit.Power.Keys.CH0J,
                    info: SMCKitKeyInfoData(
                        dataSize: 1,
                        dataType: SMCKitType.ui8,
                        dataAttributes: 0xD4
                    )
                ),
            ]

        public static func supported() -> Bool {
            for keyInfo in SMCKit.Power.keys {
                do {
                    let info = try SMCKit.GetKeyInfo(key: keyInfo.key)
                    guard keyInfo.info == info else {
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
                try SMCKit.WriteKeyUI8(key: SMCKit.Power.Keys.CH0C, value: 0x00)
                return true
            } catch {
                return false
            }
        }

        public static func disableCharging() -> Bool {
            do {
                try SMCKit.WriteKeyUI8(key: SMCKit.Power.Keys.CH0C, value: 0x01)
                return true
            } catch {
                return false
            }
        }

        public static func isChargingDisabled() -> Bool {
            do {
                let value = try SMCKit.ReadKeyUI8(key: SMCKit.Power.Keys.CH0C)
                return value != 0x00
            } catch {
                return false
            }
        }

        public static func enablePowerAdapter() -> Bool {
            do {
                try SMCKit.WriteKeyUI8(key: SMCKit.Power.Keys.CH0J, value: 0x00)
                return true
            } catch {
                return false
            }
        }

        public static func disablePowerAdapter() -> Bool {
            do {
                try SMCKit.WriteKeyUI8(key: SMCKit.Power.Keys.CH0J, value: 0x20)
                return true
            } catch {
                return false
            }
        }

        public static func isPowerAdapterDisabled() -> Bool {
            do {
                let value = try SMCKit.ReadKeyUI8(key: SMCKit.Power.Keys.CH0J)
                return value != 0x00
            } catch {
                return false
            }
        }
    }
}
