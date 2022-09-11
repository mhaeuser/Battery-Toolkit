import Foundation

@objc public protocol BTServiceCommProtocol {
    func askAuthorization(reply: @escaping ((NSData?) -> Void)) -> Void
}
