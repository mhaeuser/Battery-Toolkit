//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

@MainActor
internal enum BTDaemonXPCClient {
    private static var connect: NSXPCConnection? = nil

    private static func connectDaemon() -> NSXPCConnection {
        if let connect = BTDaemonXPCClient.connect {
            return connect
        }

        let connect = NSXPCConnection(
            machServiceName: BT_DAEMON_NAME,
            options: .privileged
        )
        connect.remoteObjectInterface = NSXPCInterface(
            with: BTDaemonCommProtocol.self
        )

        BTXPCValidation.protectDaemon(connection: connect)

        connect.resume()
        BTDaemonXPCClient.connect = connect

        os_log("XPC client connected")

        return connect
    }

    private static func executeDaemon(
        command: @MainActor @escaping @Sendable (BTDaemonCommProtocol) -> Void,
        errorHandler: @escaping @Sendable (any Error) -> Void
    ) {
        let connect = self.connectDaemon()
        let daemon = connect.remoteObjectProxyWithErrorHandler(
            errorHandler
        ) as! BTDaemonCommProtocol
        command(daemon)
    }

    private static func executeDaemonRetry(
        errorHandler: @escaping @Sendable (BTError.RawValue) -> Void,
        command: @MainActor @escaping @Sendable (BTDaemonCommProtocol) -> Void
    ) {
        self.executeDaemon(command: command) { error in
            os_log(
                "XPC client remote error, retrying: \(error.localizedDescription)"
            )
            DispatchQueue.main.async {
                disconnectDaemon()
                executeDaemon(command: command) { error in
                    os_log(
                        "XPC client remote object error: \(error.localizedDescription)"
                    )
                    errorHandler(BTError.commFailed.rawValue)
                }
            }
        }
    }

    private static func executeDaemonManageRetry(
        reply: @escaping @Sendable (BTError.RawValue) -> Void,
        command: @MainActor @escaping @Sendable (
            BTDaemonCommProtocol,
            AuthorizationRef,
            @Sendable @escaping (BTError.RawValue) -> Void
        ) -> Void
    ) {
        BTAuthorizationService.manage { authRef in
            guard let authRef else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            DispatchQueue.main.async {
                self.executeDaemonRetry(errorHandler: reply) { daemon in
                    command(daemon, authRef, reply)
                }
            }
        }
    }

    private static func runExecute(
        command: BTDaemonCommCommand,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonManageRetry(reply: reply) { daemon, authRef, reply in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: command.rawValue,
                reply: reply
            )
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

    internal static func getUniqueId(
        reply: @Sendable @escaping (NSData?) -> Void
    ) {
        self.executeDaemonRetry { _ in
            reply(nil)
        } command: { daemon in
            daemon.getUniqueId(reply: reply)
        }
    }

    internal static func getState(
        reply: @Sendable @escaping (BTError.RawValue, [String: NSObject])
            -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error, [:])
        } command: { daemon in
            daemon.getState { state in
                reply(BTError.success.rawValue, state)
            }
        }
    }

    internal static func disablePowerAdapter(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.disablePowerAdapter,
            reply: reply
        )
    }

    internal static func enablePowerAdapter(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.enablePowerAdapter,
            reply: reply
        )
    }

    internal static func chargeToMaximum(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.chargeToMaximum,
            reply: reply
        )
    }

    internal static func chargeToFull(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(command: BTDaemonCommCommand.chargeToFull, reply: reply)
    }

    internal static func disableCharging(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.disableCharging,
            reply: reply
        )
    }

    internal static func getSettings(
        reply: @Sendable @escaping (BTError.RawValue, [String: NSObject])
            -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error, [:])
        } command: { daemon in
            daemon.getSettings { settings in
                reply(BTError.success.rawValue, settings)
            }
        }
    }

    internal static func setSettings(
        settings: [String: NSObject],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonManageRetry(reply: reply) { daemon, authRef, reply in
            daemon.setSettings(
                authData: BTAuthorization.toData(authRef: authRef),
                settings: settings,
                reply: reply
            )
        }
    }

    @Sendable private nonisolated static func emptyErrorHandler(
        error _: BTError.RawValue
    ) {
        //
        // Deliberately ignore errors as this is an optional notification.
        //
    }

    internal static func prepareUpdate() {
        self.executeDaemonRetry(
            errorHandler: self.emptyErrorHandler
        ) { daemon in
            daemon.execute(
                authData: nil,
                command: BTDaemonCommCommand.prepareUpdate.rawValue,
                reply: emptyErrorHandler
            )
        }
    }

    internal static func finishUpdate() {
        self.executeDaemonRetry(
            errorHandler: self.emptyErrorHandler
        ) { daemon in
            daemon.execute(
                authData: nil,
                command: BTDaemonCommCommand.finishUpdate.rawValue,
                reply: emptyErrorHandler
            )
        }
    }

    internal static func removeLegacyHelperFiles(
        authRef: AuthorizationRef,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error)
        } command: { daemon in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommCommand.removeLegacyHelperFiles.rawValue,
                reply: reply
            )
        }
    }

    internal static func prepareDisable(
        authRef: AuthorizationRef,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error)
        } command: { daemon in
            daemon.execute(
                authData: BTAuthorization.toData(authRef: authRef),
                command: BTDaemonCommCommand.prepareDisable.rawValue,
                reply: reply
            )
        }
    }

    internal static func isSupported(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error)
        } command: { daemon in
            daemon.execute(
                authData: nil,
                command: BTDaemonCommCommand.isSupported.rawValue,
                reply: reply
            )
        }
    }
}
