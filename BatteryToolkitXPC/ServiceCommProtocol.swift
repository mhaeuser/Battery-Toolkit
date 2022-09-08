import Foundation

@objc protocol BTServiceCommProtocol {
    func askAuthorization(reply: @escaping ((NSData?) -> Void)) -> Void
}
