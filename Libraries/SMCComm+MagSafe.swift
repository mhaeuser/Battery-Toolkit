//
// Copyright (C) 2024 - 2025 Marvin Häuser. All rights reserved.
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
            self.supported = SMCComm.keySupported(keyInfo: self.Keys.ACLC)
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
        static let ACLC = SMCComm.KeyInfo(
            key: SMCComm.Key("A", "C", "L", "C"),
            info: SMCComm.KeyInfoData(
                dataSize: 1,
                dataType: SMCComm.KeyTypes.ui8,
                dataAttributes: 0xD4
            )
        )
    }

    private static func setColor(color: UInt8) -> Bool {
        guard self.supported else {
            return false
        }

        return SMCComm.writeKey(key: self.Keys.ACLC.key, bytes: [color])
    }
}
