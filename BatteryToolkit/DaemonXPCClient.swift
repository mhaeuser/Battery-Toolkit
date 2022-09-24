/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

@MainActor
internal struct BTDaemonXPCClient {
    private static var connect: NSXPCConnection? = nil

    private static func connectDaemon() -> NSXPCConnection {
        if let connect = BTDaemonXPCClient.connect {
            return connect
        }

        let connect = NSXPCConnection(
            machServiceName: BT_DAEMON_NAME,
            options: .privileged
            )
        connect.remoteObjectInterface = NSXPCInterface(with: BTDaemonCommProtocol.self)
        connect.resume()
        BTDaemonXPCClient.connect = connect

        os_log("XPC client connected")

        return connect
    }


    private static func executeDaemon(command: @MainActor @escaping @Sendable (BTDaemonCommProtocol) -> Void, errorHandler: @escaping @Sendable (any Error) -> Void) {
        let connect = connectDaemon()
        let daemon = connect.remoteObjectProxyWithErrorHandler(errorHandler) as! BTDaemonCommProtocol
        command(daemon)
    }

    private static func executeDaemonRetry(errorHandler: @escaping @Sendable (BTError.RawValue) -> Void, command: @MainActor @escaping @Sendable (BTDaemonCommProtocol) -> Void) {
        executeDaemon(command: command) { error in
            os_log("XPC client remote error, retrying: \(error.localizedDescription)")
            DispatchQueue.main.async {
                disconnectDaemon()
                executeDaemon(command: command) { error in
                    os_log("XPC client remote object error: \(error.localizedDescription)")
                    errorHandler(BTError.commFailed.rawValue)
                }
            }
        }
    }

    private static func executeDaemonManageRetry(errorHandler: @escaping @Sendable (BTError.RawValue) -> Void, command: @MainActor @escaping @Sendable (BTDaemonCommProtocol, AuthorizationRef) -> Void) {
        BTAuthorizationService.manage() { authRef in
            guard let authRef = authRef else {
                errorHandler(BTError.notAuthorized.rawValue)
                return
            }

            executeDaemonRetry(errorHandler: errorHandler) { daemon in
                command(daemon, authRef)
            }
        }
    }

    internal static func disconnectDaemon() {
        guard let connect = BTDaemonXPCClient.connect else {
            return
        }

        BTDaemonXPCClient.connect = nil
        connect.invalidate()
    }

    internal static func stop() {
        guard let connect = BTDaemonXPCClient.connect else {
            return
        }

        BTDaemonXPCClient.connect = nil

        connect.invalidate()
    }

    internal static func getUniqueId(reply: @Sendable @escaping (NSData?) -> Void) -> Void {
        executeDaemonRetry() { _ in
            reply(nil)
        } command: { daemon in
            daemon.getUniqueId(reply: reply)
        }
    }

    internal static func getState(reply: @Sendable @escaping (BTError.RawValue, [String: AnyObject]) -> Void) -> Void {
        executeDaemonRetry() { error in
            reply(error, [:])
        } command: { daemon in
            daemon.getState { state in
                reply(BTError.success.rawValue, state)
            }
        }
    }

    internal static func disablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        executeDaemonManageRetry(errorHandler: reply) { (daemon, authRef) in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommProtocolCommands.disablePowerAdapter.rawValue,
                reply: reply
                )
        }
    }

    internal static func enablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        executeDaemonManageRetry(errorHandler: reply) { (daemon, authRef) in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommProtocolCommands.enablePowerAdapter.rawValue,
                reply: reply
                )
        }
    }

    internal static func chargeToMaximum(reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        executeDaemonManageRetry(errorHandler: reply) { (daemon, authRef) in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommProtocolCommands.chargeToMaximum.rawValue,
                reply: reply
                )
        }
    }

    internal static func chargeToFull(reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        executeDaemonManageRetry(errorHandler: reply) { (daemon, authRef) in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommProtocolCommands.chargeToFull.rawValue,
                reply: reply
                )
        }
    }

    internal static func disableCharging(reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        executeDaemonManageRetry(errorHandler: reply) { (daemon, authRef) in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommProtocolCommands.disableCharging.rawValue,
                reply: reply
                )
        }
    }

    internal static func getSettings(reply: @Sendable @escaping (BTError.RawValue, [String: AnyObject]) -> Void) {
        executeDaemonRetry() { error in
            reply(error, [:])
        } command: { daemon in
            daemon.getSettings() { settings in
                reply(BTError.success.rawValue, settings)
            }
        }
    }
    
    internal static func setSettings(settings: [String: AnyObject], reply: @Sendable @escaping (BTError.RawValue) -> Void) -> Void {
        executeDaemonManageRetry(errorHandler: reply) { (daemon, authRef) in
            daemon.setSettings(
                authData: BTAuthorization.toData(authRef: authRef),
                settings: settings,
                reply: reply
                )
        }
    }

    internal static func removeLegacyHelperFiles(authRef: AuthorizationRef, reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        executeDaemonRetry() { error in
            reply(error)
        } command: { daemon in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommProtocolCommands.removeLegacyHelperFiles.rawValue,
                reply: reply
                )
        }
    }
}
