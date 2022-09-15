import Foundation

extension BTDaemonManagement {
    internal enum Status: UInt8 {
        case notRegistered    = 0
        case enabled          = 1
        case requiresApproval = 2
    }
}
