//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCComm {
    @MainActor
    enum Power {
        private enum Keys {
            fileprivate static let CH0C = SMCCommKey("C", "H", "0", "C")
            fileprivate static let CH0J = SMCCommKey("C", "H", "0", "J")
        }

        private static let keys =
            [
                SMCCommKeyInfo(
                    key: SMCComm.Power.Keys.CH0C,
                    info: SMCCommKeyInfoData(
                        dataSize: 1,
                        dataType: SMCCommType.hex,
                        dataAttributes: 0xD4
                    )
                ),
                SMCCommKeyInfo(
                    key: SMCComm.Power.Keys.CH0J,
                    info: SMCCommKeyInfoData(
                        dataSize: 1,
                        dataType: SMCCommType.ui8,
                        dataAttributes: 0xD4
                    )
                ),
            ]

        public static func supported() -> Bool {
            for keyInfo in SMCComm.Power.keys {
                do {
                    let info = try SMCComm.GetKeyInfo(key: keyInfo.key)
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
                try SMCComm.WriteKeyUI8(
                    key: SMCComm.Power.Keys.CH0C,
                    value: 0x00
                )
                return true
            } catch {
                return false
            }
        }

        public static func disableCharging() -> Bool {
            do {
                try SMCComm.WriteKeyUI8(
                    key: SMCComm.Power.Keys.CH0C,
                    value: 0x01
                )
                return true
            } catch {
                return false
            }
        }

        public static func isChargingDisabled() -> Bool {
            do {
                let value = try SMCComm.ReadKeyUI8(key: SMCComm.Power.Keys.CH0C)
                return value != 0x00
            } catch {
                return false
            }
        }

        public static func enablePowerAdapter() -> Bool {
            do {
                try SMCComm.WriteKeyUI8(
                    key: SMCComm.Power.Keys.CH0J,
                    value: 0x00
                )
                return true
            } catch {
                return false
            }
        }

        public static func disablePowerAdapter() -> Bool {
            do {
                try SMCComm.WriteKeyUI8(
                    key: SMCComm.Power.Keys.CH0J,
                    value: 0x20
                )
                return true
            } catch {
                return false
            }
        }

        public static func isPowerAdapterDisabled() -> Bool {
            do {
                let value = try SMCComm.ReadKeyUI8(key: SMCComm.Power.Keys.CH0J)
                return value != 0x00
            } catch {
                return false
            }
        }
    }
}
