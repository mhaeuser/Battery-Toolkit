/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

@MainActor
internal struct BTDaemonXPCClient {
    private struct Handlers {
        fileprivate static func interruption() {
            os_log("XPC client connection interrupted")
        }

        fileprivate static func invalidation() {
            DispatchQueue.main.async {
                BTDaemonXPCClient.connect = nil
            }

            os_log("XPC client connection invalidated")
        }
    }

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
        
        connect.invalidationHandler = BTDaemonXPCClient.Handlers.invalidation
        connect.interruptionHandler = BTDaemonXPCClient.Handlers.interruption
        
        connect.resume()

        BTDaemonXPCClient.connect = connect

        os_log("XPC client connected")

        return connect
    }

    private static func getDaemon(errorHandler: @escaping @Sendable () -> Void) -> BTDaemonCommProtocol {
        let connect = connectDaemon()

        let daemon = connect.remoteObjectProxyWithErrorHandler({ error in
            // FIXME: Properly handle errors, e.g. force reinstall daemon.

            os_log("XPC client remote object error: \(error.localizedDescription)")
            errorHandler()
        }) as! BTDaemonCommProtocol

        return daemon
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
        let daemon = getDaemon() {
            reply(nil)
        }

        daemon.getUniqueId(reply: reply)
    }

    internal static func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
        let daemon = getDaemon() {
            reply([:])
        }

        daemon.getState(reply: reply)
    }

    internal static func disablePowerAdapter(reply: @Sendable @escaping (Bool) -> Void) -> Void {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.execute(
            command: BTDaemonCommProtocolCommands.disablePowerAdapter.rawValue,
            reply: reply
            )
    }

    internal static func enablePowerAdapter(reply: @Sendable @escaping (Bool) -> Void) -> Void {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.execute(
            command: BTDaemonCommProtocolCommands.enablePowerAdapter.rawValue,
            reply: reply
            )
    }

    internal static func chargeToMaximum(reply: @Sendable @escaping (Bool) -> Void) -> Void {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.execute(
            command: BTDaemonCommProtocolCommands.chargeToMaximum.rawValue,
            reply: reply
            )
    }

    internal static func chargeToFull(reply: @Sendable @escaping (Bool) -> Void) -> Void {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.execute(
            command: BTDaemonCommProtocolCommands.chargeToFull.rawValue,
            reply: reply
            )
    }

    internal static func disableCharging(reply: @Sendable @escaping (Bool) -> Void) -> Void {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.execute(
            command: BTDaemonCommProtocolCommands.disableCharging.rawValue,
            reply: reply
            )
    }

    internal static func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        let daemon = getDaemon() {
            reply([:])
        }

        daemon.getSettings(reply: reply)
    }
    
    internal static func setSettings(settings: [String: AnyObject], reply: @Sendable @escaping (Bool) -> Void) -> Void {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.setSettings(settings: settings, reply: reply)
    }

    internal static func removeLegacyHelperFiles(reply: @Sendable @escaping (Bool) -> Void) {
        let daemon = getDaemon() {
            reply(false)
        }

        daemon.execute(
            command: BTDaemonCommProtocolCommands.removeLegacyHelperFiles.rawValue,
            reply: reply
            )
    }
}
