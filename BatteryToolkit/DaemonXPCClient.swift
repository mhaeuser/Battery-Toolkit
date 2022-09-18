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
        let connect = BTDaemonXPCClient.connectDaemon()

        let daemon = connect.remoteObjectProxyWithErrorHandler({ error in
            // FIXME: Properly handle errors, e.g. force reinstall daemon.

            os_log("XPC client remote object error: \(error.localizedDescription)")
            errorHandler()
        }) as! BTDaemonCommProtocol

        return daemon
    }

    private static func getDaemon() -> BTDaemonCommProtocol {
        return BTDaemonXPCClient.getDaemon() { }
    }
    
    internal static func stop() {
        guard let connect = BTDaemonXPCClient.connect else {
            return
        }

        BTDaemonXPCClient.connect = nil

        connect.invalidate()
    }

    internal static func getUniqueId(reply: @Sendable @escaping (NSData?) -> Void) -> Void {
        let daemon = BTDaemonXPCClient.getDaemon() {
            reply(nil)
            return
        }

        daemon.getUniqueId(reply: reply)
    }

    internal static func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
        let daemon = BTDaemonXPCClient.getDaemon() {
            reply([:])
            return
        }

        daemon.getState(reply: reply)
    }

    internal static func disablePowerAdapter() -> Void {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.execute(
            command: BTDaemonCommProtocolCommands.disablePowerAdapter.rawValue
            )
    }

    internal static func enablePowerAdapter() -> Void {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.execute(
            command: BTDaemonCommProtocolCommands.enablePowerAdapter.rawValue
            )
    }

    internal static func chargeToMaximum() -> Void {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.execute(
            command: BTDaemonCommProtocolCommands.chargeToMaximum.rawValue
            )
    }

    internal static func chargeToFull() -> Void {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.execute(
            command: BTDaemonCommProtocolCommands.chargeToFull.rawValue
            )
    }

    internal static func disableCharging() -> Void {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.execute(
            command: BTDaemonCommProtocolCommands.disableCharging.rawValue
        )
    }

    internal static func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        let daemon = BTDaemonXPCClient.getDaemon() {
            reply([:])
            return
        }

        daemon.getSettings(reply: reply)
    }
    
    internal static func setSettings(settings: [String: AnyObject]) -> Void {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.setSettings(settings: settings)
    }

    internal static func removeLegacyHelperFiles() {
        let daemon = BTDaemonXPCClient.getDaemon()
        daemon.execute(
            command: BTDaemonCommProtocolCommands.removeLegacyHelperFiles.rawValue
            )
    }
}
