//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log
import ServiceManagement

internal final class BTDaemonComm: NSObject, BTDaemonCommProtocol, Sendable {
    @MainActor func getUniqueId(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        reply(BTDaemon.getUniqueId())
    }

    @MainActor func execute(
        authData: Data?,
        command: UInt8,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        //
        // Report the supported state to the client, so that it can, e.g.,
        // cleanly uninstall itself if it is unsupported.
        //
        if command == BTDaemonCommCommand.isSupported.rawValue {
            reply(
                BTDaemon.supported ?
                    BTError.success.rawValue :
                    BTError.unsupported.rawValue
            )
            return
        }
        //
        // The update commands are optional notifications that allow to optimise
        // the process. Usually, the platform power state is reset to its
        // defaults when the daemon exits. These signals may be used to
        // temporarily override this behaviour to preserve the state instead.
        //
        if command == BTDaemonCommCommand.prepareUpdate.rawValue {
            os_log("Preparing update")
            BTPowerEvents.updating = true
            reply(BTError.success.rawValue)
            return
        } else if command == BTDaemonCommCommand.finishUpdate.rawValue {
            os_log("Update finished")
            BTPowerEvents.updating = false
            reply(BTError.success.rawValue)
            return
        }

        let simpleAuth = SimpleAuth.fromData(authData: authData)
        guard let simpleAuth else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        self.executeWithAuth(
            simpleAuth: simpleAuth,
            command: command,
            reply: reply
        )
    }

    @MainActor func getState(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    ) {
        guard BTDaemon.supported else {
            reply([:])
            return
        }

        reply(BTDaemon.getState())
    }

    @MainActor func getSettings(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    ) {
        guard BTDaemon.supported else {
            reply([:])
            return
        }

        reply(BTSettings.getSettings())
    }

    @MainActor func setSettings(
        authData: Data,
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        //
        // Power state management functions may only be invoked when supported.
        //
        guard BTDaemon.supported else {
            reply(BTError.unsupported.rawValue)
            return
        }

        let simpleAuth = SimpleAuth.fromData(authData: authData)
        guard let simpleAuth else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        let authorized = SimpleAuth.checkRight(
            simpleAuth: simpleAuth,
            rightName: BTAuthorizationRights.manage
        )
        guard authorized else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        BTSettings.setSettings(settings: settings, reply: reply)
    }

    @MainActor private func executeWithAuth(
        simpleAuth: SimpleAuthRef,
        command: UInt8,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        guard command != BTDaemonCommCommand.removeLegacyHelperFiles.rawValue
        else {
            let authorized = SimpleAuth.checkRight(
                simpleAuth: simpleAuth,
                rightName: kSMRightModifySystemDaemons
            )
            guard authorized else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            let success = BTDaemonManagement.removeLegacyHelperFiles()
            reply(BTError(fromBool: success).rawValue)
            return
        }

        guard command != BTDaemonCommCommand.prepareDisable.rawValue else {
            let authorized = SimpleAuth.checkRight(
                simpleAuth: simpleAuth,
                rightName: kSMRightModifySystemDaemons
            )
            guard authorized else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            let success = BTDaemonManagement.prepareDisable()
            reply(BTError(fromBool: success).rawValue)
            return
        }
        //
        // Power state management functions may only be invoked when supported.
        //
        guard BTDaemon.supported else {
            reply(BTError.unsupported.rawValue)
            return
        }

        let authorized = SimpleAuth.checkRight(
            simpleAuth: simpleAuth,
            rightName: BTAuthorizationRights.manage
        )
        guard authorized else {
            reply(BTError.notAuthorized.rawValue)
            return
        }

        let success = self.executeManage(command: command)
        reply(BTError(fromBool: success).rawValue)
    }

    @MainActor private func executeManage(command: UInt8) -> Bool {
        switch command {
        case BTDaemonCommCommand.disablePowerAdapter.rawValue:
            return BTPowerState.disablePowerAdapter()

        case BTDaemonCommCommand.enablePowerAdapter.rawValue:
            return BTPowerState.enablePowerAdapter()

        case BTDaemonCommCommand.chargeToFull.rawValue:
            return BTPowerEvents.chargeToFull()

        case BTDaemonCommCommand.chargeToMaximum.rawValue:
            return BTPowerEvents.chargeToMaximum()

        case BTDaemonCommCommand.disableCharging.rawValue:
            return BTPowerEvents.disableCharging()

        default:
            os_log("Unknown command: \(command)")
            return false
        }
    }
}
