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

    /// SIGTERM source signal. Needs to be preserved for the program lifetime.
    private static var termSource: DispatchSourceSignal? = nil

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
        //
        // Cache the unique ID immediately, as this is not safe against
        // modifications of the daemon on-disk. This ID must not be used for
        // security-criticial purposes.
        //
        self.uniqueId = CSIdentification.getUniqueIdSelf()

        BTSettings.readDefaults()
        
        GlobalSleep.restoreOnStart()

        do {
            try BTPowerEvents.start()
            self.supported = true

            let termSource = DispatchSource.makeSignalSource(
                signal: SIGTERM,
                queue: DispatchQueue.main
            )
            termSource.setEventHandler {
                BTPowerEvents.exit()
                exit(0)
            }
            termSource.resume()
            //
            // Preserve termSource globally, so it is not deallocated.
            //
            self.termSource = termSource
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
        } catch BTError.unsupported {
            //
            // Still run the XPC server if the machine is unsupported to cleanly
            // uninstall the daemon, but don't initialize the rest of the stack.
            //
            self.supported = false
        } catch {
            os_log("Power events start failed")
            exit(-1)
        }

        BTDaemonXPCServer.start()

        dispatchMain()
    }
}
