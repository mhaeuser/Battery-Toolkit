import Foundation

class BTCClientComm : NSObject, BTClientCommProtocol {
    func submitExternalPowerEnabled(enabled: Bool) -> Void {
        debugPrint("External Power: ", enabled)
    }
}
