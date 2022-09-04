import Foundation

@objc protocol BTServiceCommProtocol {
    func installHelper(reply: @escaping ((Bool) -> Void)) -> Void
}
