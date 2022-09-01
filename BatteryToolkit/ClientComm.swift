import Foundation

public final class BTCClientComm : NSObject, BTClientCommProtocol {
    func submitExternalPowerEnabled(enabled: Bool) -> Void {
        debugPrint("External Power: ", enabled)
    }
}
