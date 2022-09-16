/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor

internal struct BTHelperXPCClient {
    private static var connect: NSXPCConnection?     = nil
    private static var helper: BTHelperCommProtocol? = nil

    private static func interruptionHandler() {
        os_log("XPC client connection interrupted")
    }
    
    private static func invalidationHandler() {
        os_log("XPC client connection invalidated")
        BTHelperXPCClient.connect = nil
        BTHelperXPCClient.helper  = nil
    }

    internal static func connectDaemon() {
        if BTHelperXPCClient.connect != nil {
            assert(BTHelperXPCClient.helper != nil)
            return
        }
        
        assert(BTHelperXPCClient.helper == nil)

        let lConnect = NSXPCConnection(
            machServiceName: BT_DAEMON_NAME,
            options: .privileged
            )

        lConnect.remoteObjectInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        
        lConnect.invalidationHandler = BTHelperXPCClient.invalidationHandler
        lConnect.interruptionHandler = BTHelperXPCClient.interruptionHandler
        
        lConnect.resume()
        
        guard let lHelper = lConnect.remoteObjectProxyWithErrorHandler({ error in
            os_log("XPC client remote object error: \(error)")
        }) as? BTHelperCommProtocol else {
            os_log("XPC client remote object is malfored")
            lConnect.invalidate()
            return
        }
        
        os_log("XPC client connected")
        
        connect = lConnect
        helper  = lHelper
    }
    
    internal static func stop() {
        guard let lConnect = BTHelperXPCClient.connect else {
            assert(BTHelperXPCClient.helper == nil)
            return
        }
        
        assert(BTHelperXPCClient.helper != nil)

        BTHelperXPCClient.connect = nil
        BTHelperXPCClient.helper  = nil

        lConnect.invalidate()
    }
    
    internal static func getState(reply: @escaping (([String: AnyObject]) -> Void)) -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.getState(reply: reply)
    }

    internal static func disablePowerAdapter() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.execute(
            command: BTHelperCommProtocolCommands.disablePowerAdapter.rawValue
            )
    }

    internal static func enablePowerAdapter() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.execute(
            command: BTHelperCommProtocolCommands.enablePowerAdapter.rawValue
            )
    }

    internal static func chargeToMaximum() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.execute(
            command: BTHelperCommProtocolCommands.chargeToMaximum.rawValue
            )
    }

    internal static func chargeToFull() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.execute(
            command: BTHelperCommProtocolCommands.chargeToFull.rawValue
            )
    }

    internal static func disableCharging() -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.execute(
            command: BTHelperCommProtocolCommands.disableCharging.rawValue
        )
    }

    internal static func getSettings(reply: @escaping (([String: AnyObject]) -> Void)) {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.getSettings(reply: reply)
    }
    
    internal static func setSettings(settings: [String: AnyObject]) -> Void {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.setSettings(settings: settings)
    }

    internal static func removeHelperFiles() {
        BTHelperXPCClient.connectDaemon()
        BTHelperXPCClient.helper?.execute(
            command: BTHelperCommProtocolCommands.removeHelperFiles.rawValue
            )
    }
}
