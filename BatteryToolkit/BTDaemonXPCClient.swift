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

    static func disconnectDaemon() {
        guard let connect = self.connect else {
            return
        }

        self.connect = nil
        connect.invalidate()
    }

    static func stop() {
        guard let connect = self.connect else {
            return
        }

        self.connect = nil

        connect.invalidate()
    }

    static func getUniqueId(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        self.executeDaemonRetry { _ in
            reply(nil)
        } command: { daemon in
            daemon.getUniqueId(reply: reply)
        }
    }

    static func getState(
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

    static func disablePowerAdapter(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.disablePowerAdapter,
            reply: reply
        )
    }

    static func enablePowerAdapter(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.enablePowerAdapter,
            reply: reply
        )
    }

    static func chargeToMaximum(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.chargeToMaximum,
            reply: reply
        )
    }

    static func chargeToFull(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(command: BTDaemonCommCommand.chargeToFull, reply: reply)
    }

    static func disableCharging(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.runExecute(
            command: BTDaemonCommCommand.disableCharging,
            reply: reply
        )
    }

    static func getSettings(
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

    static func setSettings(
        settings: [String: NSObject],
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonManageRetry(reply: reply) { daemon, authData, reply in
            daemon.setSettings(
                authData: authData,
                settings: settings,
                reply: reply
            )
        }
    }

    static func prepareUpdate(
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonRetry(
            errorHandler: reply
        ) { daemon in
            daemon.execute(
                authData: nil,
                command: BTDaemonCommCommand.prepareUpdate.rawValue,
                reply: reply
            )
        }
    }

    static func finishUpdate() {
        //
        // Deliberately ignore errors as this is an optional notification.
        //
        self.executeDaemonRetry(
            errorHandler: { _ in }
        ) { daemon in
            daemon.execute(
                authData: nil,
                command: BTDaemonCommCommand.finishUpdate.rawValue,
                reply: { _ in }
            )
        }
    }

    static func removeLegacyHelperFiles(
        authData: Data,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error)
        } command: { daemon in
            daemon.execute(
                authData: authData,
                command: BTDaemonCommCommand.removeLegacyHelperFiles.rawValue,
                reply: reply
            )
        }
    }

    static func prepareDisable(
        authData: Data,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonRetry { error in
            reply(error)
        } command: { daemon in
            daemon.execute(
                authData: authData,
                command: BTDaemonCommCommand.prepareDisable.rawValue,
                reply: reply
            )
        }
    }

    static func isSupported(
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

    private static func connectDaemon() -> NSXPCConnection {
        if let connect = self.connect {
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
        self.connect = connect

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
            Data,
            @Sendable @escaping (BTError.RawValue) -> Void
        ) -> Void
    ) {
        BTAppXPCClient.getManageAuthorization { authData in
            guard let authData else {
                reply(BTError.notAuthorized.rawValue)
                return
            }

            DispatchQueue.main.async {
                self.executeDaemonRetry(errorHandler: reply) { daemon in
                    command(daemon, authData) { error in
                        reply(error)
                    }
                }
            }
        }
    }

    private static func runExecute(
        command: BTDaemonCommCommand,
        reply: @Sendable @escaping (BTError.RawValue) -> Void
    ) {
        self.executeDaemonManageRetry(reply: reply) { daemon, authData, reply in
            daemon.execute(
                authData: authData,
                command: command.rawValue,
                reply: reply
            )
        }
    }
}
