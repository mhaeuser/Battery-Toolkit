import Foundation

public final class BTCClientComm : NSObject, BTClientCommProtocol {
    func submitPowerAdapterEnabled(enabled: Bool) -> Void {
        debugPrint("External Power: ", enabled)
    }
}
