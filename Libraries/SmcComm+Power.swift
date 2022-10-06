//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SmcComm {
    @MainActor
    enum Power {
        private enum Keys {
            fileprivate static let CH0C = SmcCommKey("C", "H", "0", "C")
            fileprivate static let CH0J = SmcCommKey("C", "H", "0", "J")
        }

        private static let keys =
            [
                SmcCommKeyInfo(
                    key: SmcComm.Power.Keys.CH0C,
                    info: SmcCommKeyInfoData(
                        dataSize: 1,
                        dataType: SmcCommType.hex,
                        dataAttributes: 0xD4
                    )
                ),
                SmcCommKeyInfo(
                    key: SmcComm.Power.Keys.CH0J,
                    info: SmcCommKeyInfoData(
                        dataSize: 1,
                        dataType: SmcCommType.ui8,
                        dataAttributes: 0xD4
                    )
                ),
            ]

        public static func supported() -> Bool {
            for keyInfo in SmcComm.Power.keys {
                do {
                    let info = try SmcComm.GetKeyInfo(key: keyInfo.key)
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
                try SmcComm.WriteKeyUI8(
                    key: SmcComm.Power.Keys.CH0C,
                    value: 0x00
                )
                return true
            } catch {
                return false
            }
        }

        public static func disableCharging() -> Bool {
            do {
                try SmcComm.WriteKeyUI8(
                    key: SmcComm.Power.Keys.CH0C,
                    value: 0x01
                )
                return true
            } catch {
                return false
            }
        }

        public static func isChargingDisabled() -> Bool {
            do {
                let value = try SmcComm.ReadKeyUI8(key: SmcComm.Power.Keys.CH0C)
                return value != 0x00
            } catch {
                return false
            }
        }

        public static func enablePowerAdapter() -> Bool {
            do {
                try SmcComm.WriteKeyUI8(
                    key: SmcComm.Power.Keys.CH0J,
                    value: 0x00
                )
                return true
            } catch {
                return false
            }
        }

        public static func disablePowerAdapter() -> Bool {
            do {
                try SmcComm.WriteKeyUI8(
                    key: SmcComm.Power.Keys.CH0J,
                    value: 0x20
                )
                return true
            } catch {
                return false
            }
        }

        public static func isPowerAdapterDisabled() -> Bool {
            do {
                let value = try SmcComm.ReadKeyUI8(key: SmcComm.Power.Keys.CH0J)
                return value != 0x00
            } catch {
                return false
            }
        }
    }
}
