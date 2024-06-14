//
// Copyright (C) 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

public extension SMCComm {
    @MainActor
    enum MagSafe {
        private(set) static var supported = false

        static func prepare() {
            //
            // Ensure all required SMC keys are present and well-formed.
            //
            for keyInfo in self.keys {
                let info = SMCComm.getKeyInfo(key: keyInfo.key)
                guard let info = info,
                      SMCComm.KeyInfoDataEq(data1: keyInfo.info, data2: info) else {
                    self.supported = false
                    return
                }
            }

            self.supported = true
        }

        static func setSystem() -> Bool {
            return self.setColor(color: 0x00)
        }

        static func setOff() -> Bool {
            return self.setColor(color: 0x01)
        }

        static func setGreen() -> Bool {
            return self.setColor(color: 0x03)
        }

        static func setOrange() -> Bool {
            return self.setColor(color: 0x04)
        }

        static func setOrangeSlowBlink() -> Bool {
            return self.setColor(color: 0x06)
        }

        static func setOrangeFastBlink() -> Bool {
            return self.setColor(color: 0x07)
        }

        static func setOrangeBlinkOff() -> Bool {
            return self.setColor(color: 0x19)
        }
    }
}

private extension SMCComm.MagSafe {
    private enum Keys {
        static let ACLC = SMCComm.Key("A", "C", "L", "C")
    }

    private static let keys =
        [
            SMCComm.KeyInfo(
                key: SMCComm.MagSafe.Keys.ACLC,
                info: SMCComm.KeyInfoData(
                    dataSize: 1,
                    dataType: SMCComm.KeyTypes.ui8,
                    dataAttributes: 0xD4
                )
            ),
        ]

    private static func setColor(color: UInt8) -> Bool {
        guard self.supported else {
            return false
        }

        return SMCComm.writeKeyUI8(key: self.Keys.ACLC, value: color)
    }
}
