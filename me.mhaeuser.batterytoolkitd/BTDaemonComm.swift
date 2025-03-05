//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log
import ServiceManagement

internal final class BTDaemonComm: NSObject, BTDaemonCommProtocol, Sendable {
    func getUniqueId(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        Task { @MainActor in
            reply(BTDaemon.getUniqueId())
        }
    }

    func execute(
        authData: Data?,
        command: UInt8,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        Task { @MainActor in
            switch command {
            //
            // Report the supported state to the client, so that it can, e.g.,
            // cleanly uninstall itself if it is unsupported.
            //
            case BTDaemonCommCommand.isSupported.rawValue:
                reply(
                    BTDaemon.supported ?
                        BTError.success.rawValue :
                        BTError.unsupported.rawValue
                )
                return
            //
            // The update commands are optional notifications that allow to
            // optimise the process. Usually, the platform power state is reset
            // to its defaults when the daemon exits. These signals may be used
            // to temporarily override this behaviour to preserve the state
            // instead.
            //
            case BTDaemonCommCommand.prepareUpdate.rawValue:
                os_log("Preparing update")
                BTPowerEvents.updating = true
                reply(BTError.success.rawValue)
                return
            case BTDaemonCommCommand.finishUpdate.rawValue:
                os_log("Update finished")
                BTPowerEvents.updating = false
                reply(BTError.success.rawValue)
                return

            case BTDaemonCommCommand.removeLegacyHelperFiles.rawValue:
                let authorized = self.checkRight(
                    authData: authData,
                    rightName: kSMRightModifySystemDaemons
                )
                guard authorized else {
                    reply(BTError.notAuthorized.rawValue)
                    return
                }

                let success = BTDaemonManagement.removeLegacyHelperFiles()
                reply(BTError(fromBool: success).rawValue)
                return

            case BTDaemonCommCommand.prepareDisable.rawValue:
                let authorized = self.checkRight(
                    authData: authData,
                    rightName: kSMRightModifySystemDaemons
                )
                guard authorized else {
                    reply(BTError.notAuthorized.rawValue)
                    return
                }

                let success = BTDaemonManagement.prepareDisable()
                reply(BTError(fromBool: success).rawValue)
                return

            default:
                //
                // Power state management functions may only be invoked when
                // supported.
                //
                guard BTDaemon.supported else {
                    reply(BTError.unsupported.rawValue)
                    return
                }

                switch command {
                case BTDaemonCommCommand.enablePowerAdapter.rawValue:
                    let success = BTPowerState.enablePowerAdapter()
                    reply(BTError(fromBool: success).rawValue)
                    return
                case BTDaemonCommCommand.chargeToFull.rawValue:
                    let success = BTPowerEvents.chargeToFull()
                    reply(BTError(fromBool: success).rawValue)
                    return
                case BTDaemonCommCommand.chargeToLimit.rawValue:
                    let success = BTPowerEvents.chargeToLimit()
                    reply(BTError(fromBool: success).rawValue)
                    return
                    
                case BTDaemonCommCommand.disablePowerAdapter.rawValue:
                    let authorized = self.checkRight(
                        authData: authData,
                        rightName: BTAuthorizationRights.manage
                    )
                    guard authorized else {
                        reply(BTError.notAuthorized.rawValue)
                        return
                    }

                    let success = BTPowerState.disablePowerAdapter()
                    reply(BTError(fromBool: success).rawValue)
                    return

                case BTDaemonCommCommand.disableCharging.rawValue:
                    let authorized = self.checkRight(
                        authData: authData,
                        rightName: BTAuthorizationRights.manage
                    )
                    guard authorized else {
                        reply(BTError.notAuthorized.rawValue)
                        return
                    }

                    let success = BTPowerEvents.disableCharging()
                    reply(BTError(fromBool: success).rawValue)
                    return

                case BTDaemonCommCommand.pauseActivity.rawValue:
                    let authorized = self.checkRight(
                        authData: authData,
                        rightName: BTAuthorizationRights.manage
                    )
                    guard authorized else {
                        reply(BTError.notAuthorized.rawValue)
                        return
                    }

                    BTDaemon.pause()
                    reply(BTError.success.rawValue)
                    return

                case BTDaemonCommCommand.resumeActivity.rawValue:
                    let authorized = self.checkRight(
                        authData: authData,
                        rightName: BTAuthorizationRights.manage
                    )
                    guard authorized else {
                        reply(BTError.notAuthorized.rawValue)
                        return
                    }

                    BTDaemon.resume()
                    reply(BTError.success.rawValue)
                    return

                default:
                    os_log("Unknown command: \(command)")
                    reply(BTError.commFailed.rawValue)
                    return
                }
            }
        }
    }

    func getState(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    ) {
        Task { @MainActor in
            guard BTDaemon.supported else {
                reply([:])
                return
            }
            
            reply(BTDaemon.getState())
        }
    }

    func getSettings(
        reply: @Sendable @escaping ([String: NSObject & Sendable]) -> Void
    ) {
        Task { @MainActor in
            guard BTDaemon.supported else {
                reply([:])
                return
            }
            
            reply(BTSettings.getSettings())
        }
    }

    func setSettings(
        authData: Data,
        settings: [String: NSObject & Sendable],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        Task { @MainActor in
            //
            // Power state management functions may only be invoked when
            // supported.
            //
            guard BTDaemon.supported else {
                reply(BTError.unsupported.rawValue)
                return
            }
            
            let authorized = self.checkRight(
                authData: authData,
                rightName: BTAuthorizationRights.manage
            )
            guard authorized else {
                reply(BTError.notAuthorized.rawValue)
                return
            }
            
            BTSettings.setSettings(settings: settings, reply: reply)
        }
    }

    private func checkRight(authData: Data?, rightName: String) -> Bool {
        let simpleAuth = SimpleAuth.fromData(authData: authData)
        guard let simpleAuth else {
            return false
        }

        return SimpleAuth.checkRight(
            simpleAuth: simpleAuth,
            rightName: rightName
        )
    }
}
