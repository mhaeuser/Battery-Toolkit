import Foundation

enum BTHelperCommProtocolCommands: UInt8 {
    case chargeToFull
    case chargeToMaximum
    case disablePowerAdapter
    case enablePowerAdapter
    case removeHelperFiles
}

@objc public protocol BTHelperCommProtocol {
    func execute(command: UInt8) -> Void
    func getState(reply: @escaping (([String: AnyObject]) -> Void)) -> Void
    func getSettings(reply: @escaping (([String: AnyObject]) -> Void)) -> Void
    func setSettings(settings: [String: AnyObject]) -> Void
}
