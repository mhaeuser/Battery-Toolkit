//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCComm {
    @MainActor
    enum Power {
        static func supported() -> Bool {
            //
            // Ensure all required SMC keys are present and well-formed.
            //
            for keyInfo in self.keys {
                let info = SMCComm.getKeyInfo(key: keyInfo.key)
                guard let info = info,
                      SMCComm.KeyInfoDataEq(data1: keyInfo.info, data2: info) else {
                    return false
                }
            }

            return true
        }

        static func enableCharging() -> Bool {
            return SMCComm.writeKeyUI8(key: self.Keys.CH0C, value: 0x00)
        }

        static func disableCharging() -> Bool {
            return SMCComm.writeKeyUI8(key: self.Keys.CH0C, value: 0x01)
        }

        static func isChargingDisabled() -> Bool {
            let value = SMCComm.readKeyUI8(key: self.Keys.CH0C)
            guard let value else {
                return false
            }

            return value != 0x00
        }

        static func enablePowerAdapter() -> Bool {
            return SMCComm.writeKeyUI8(key: self.Keys.CH0J, value: 0x00)
        }

        static func disablePowerAdapter() -> Bool {
            return SMCComm.writeKeyUI8(key: self.Keys.CH0J, value: 0x20)
        }

        static func isPowerAdapterDisabled() -> Bool {
            let value = SMCComm.readKeyUI8(key: self.Keys.CH0J)
            guard let value else {
                return false
            }

            return value != 0x00
        }
    }
}

private extension SMCComm.Power {
    private enum Keys {
        static let CH0C = SMCComm.Key("C", "H", "0", "C")
        static let CH0J = SMCComm.Key("C", "H", "0", "J")
    }

    private static let keys =
        [
            SMCComm.KeyInfo(
                key: SMCComm.Power.Keys.CH0C,
                info: SMCComm.KeyInfoData(
                    dataSize: 1,
                    dataType: SMCComm.KeyTypes.hex,
                    dataAttributes: 0xD4
                )
            ),
            SMCComm.KeyInfo(
                key: SMCComm.Power.Keys.CH0J,
                info: SMCComm.KeyInfoData(
                    dataSize: 1,
                    dataType: SMCComm.KeyTypes.ui8,
                    dataAttributes: 0xD4
                )
            ),
        ]
}
