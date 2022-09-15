import Foundation

public struct BTStateInfo {
    public enum ChargingMode: UInt8 {
        case standard
        case toMaximum
        case toFull
    }

    public struct Keys {
        public static let power        = "Power"
        public static let charging     = "Charging"
        public static let chargingMode = "Mode"
    }
}
