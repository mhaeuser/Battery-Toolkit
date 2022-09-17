/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

@MainActor
internal struct BTHelperXPCClient {
    private struct Handlers {
        fileprivate static func interruption() {
            os_log("XPC client connection interrupted")
        }

        fileprivate static func invalidation() {
            DispatchQueue.main.async {
                BTHelperXPCClient.connect = nil
            }

            os_log("XPC client connection invalidated")
        }
    }

    private static var connect: NSXPCConnection? = nil

    private static func connectDaemon() -> NSXPCConnection {
        if let connect = BTHelperXPCClient.connect {
            return connect
        }

        let connect = NSXPCConnection(
            machServiceName: BT_DAEMON_NAME,
            options: .privileged
            )

        connect.remoteObjectInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        
        connect.invalidationHandler = BTHelperXPCClient.Handlers.invalidation
        connect.interruptionHandler = BTHelperXPCClient.Handlers.interruption
        
        connect.resume()

        BTHelperXPCClient.connect = connect

        os_log("XPC client connected")

        return connect
    }

    private static func getHelper() -> BTHelperCommProtocol? {
        // FIXME: Properly handle errors, e.g. force reinstall daemon.

        let connect = BTHelperXPCClient.connectDaemon()

        guard let helper = connect.remoteObjectProxyWithErrorHandler({ error in
            os_log("XPC client remote object error: \(error)")
        }) as? BTHelperCommProtocol else {
            os_log("XPC client remote object is malfored")
            return nil
        }

        return helper
    }
    
    internal static func stop() {
        guard let connect = BTHelperXPCClient.connect else {
            return
        }

        BTHelperXPCClient.connect = nil

        connect.invalidate()
    }
    
    internal static func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
        guard let helper = BTHelperXPCClient.getHelper() else {
            reply([:])
            return
        }

        helper.getState(reply: reply)
    }

    internal static func disablePowerAdapter() -> Void {
        let helper = BTHelperXPCClient.getHelper()
        helper?.execute(
            command: BTHelperCommProtocolCommands.disablePowerAdapter.rawValue
            )
    }

    internal static func enablePowerAdapter() -> Void {
        let helper = BTHelperXPCClient.getHelper()
        helper?.execute(
            command: BTHelperCommProtocolCommands.enablePowerAdapter.rawValue
            )
    }

    internal static func chargeToMaximum() -> Void {
        let helper = BTHelperXPCClient.getHelper()
        helper?.execute(
            command: BTHelperCommProtocolCommands.chargeToMaximum.rawValue
            )
    }

    internal static func chargeToFull() -> Void {
        let helper = BTHelperXPCClient.getHelper()
        helper?.execute(
            command: BTHelperCommProtocolCommands.chargeToFull.rawValue
            )
    }

    internal static func disableCharging() -> Void {
        let helper = BTHelperXPCClient.getHelper()
        helper?.execute(
            command: BTHelperCommProtocolCommands.disableCharging.rawValue
        )
    }

    internal static func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        guard let helper = BTHelperXPCClient.getHelper() else {
            reply([:])
            return
        }

        helper.getSettings(reply: reply)
    }
    
    internal static func setSettings(settings: [String: AnyObject]) -> Void {
        let helper = BTHelperXPCClient.getHelper()
        helper?.setSettings(settings: settings)
    }

    internal static func removeHelperFiles() {
        let helper = BTHelperXPCClient.getHelper()
        helper?.execute(
            command: BTHelperCommProtocolCommands.removeHelperFiles.rawValue
            )
    }
}
