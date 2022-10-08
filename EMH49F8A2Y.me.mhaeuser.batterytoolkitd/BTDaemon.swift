//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

@main
@MainActor
internal enum BTDaemon {
    private(set) static var supported = false

    private static var uniqueId: Data? = nil

    static func getUniqueId() -> Data? {
        return self.uniqueId
    }

    static func getState() -> [String: NSObject & Sendable] {
        let chargingDisabled = BTPowerState.isChargingDisabled()
        let connected = BTPowerEvents.unlimitedPower
        let powerDisabled = BTPowerState.isPowerAdapterDisabled()
        let progress = BTPowerEvents.getChargingProgress()
        let mode = BTPowerEvents.chargingMode

        return [
            BTStateInfo.Keys.powerDisabled: NSNumber(value: powerDisabled),
            BTStateInfo.Keys.connected: NSNumber(value: connected),
            BTStateInfo.Keys
                .chargingDisabled: NSNumber(value: chargingDisabled),
            BTStateInfo.Keys.progress: NSNumber(value: progress.rawValue),
            BTStateInfo.Keys.chargingMode: NSNumber(value: mode.rawValue),
        ]
    }

    private static func main() {
        self.uniqueId = CSIdentification.getUniqueIdSelf()

        BTSettings.readDefaults()

        let startError = BTPowerEvents.start()
        if startError == BTError.success {
            self.supported = true

            let termSource = DispatchSource.makeSignalSource(signal: SIGTERM)
            termSource.setEventHandler {
                BTPowerEvents.exit()
                exit(0)
            }
            termSource.resume()
            //
            // Ignore SIGTERM to catch it above and gracefully stop the service.
            //
            signal(SIGTERM, SIG_IGN)

            let status = SimpleAuth.duplicateRight(
                rightName: BTAuthorizationRights.manage,
                templateName: kAuthorizationRuleAuthenticateAsAdmin,
                comment: "Used by \(BT_DAEMON_ID) to allow access to its privileged functions",
                timeout: 300
            )
            if status != errSecSuccess {
                os_log("Error adding manage right: \(status)")
            }
        } else {
            //
            // Still run the XPC server if the machine is unsupported to cleanly
            // uninstall the daemon, but don't initialize the rest of the stack.
            //
            guard startError != BTError.unsupported else {
                os_log("Power events start failed")
                exit(-1)
            }
        }

        BTDaemonXPCServer.start()

        dispatchMain()
    }
}
