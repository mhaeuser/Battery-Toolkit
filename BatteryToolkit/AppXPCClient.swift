/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import BTPreprocessor
import ServiceManagement

@MainActor
internal struct BTAppXPCClient {
    private struct Handlers {
        fileprivate static func interruption() {
            os_log("XPC app connection interrupted")
        }

        fileprivate static func invalidation() {
            DispatchQueue.main.async {
                BTAppXPCClient.connect = nil
            }

            os_log("XPC app connection invalidated")
        }
    }

    private static var connect: NSXPCConnection? = nil

    private static func connectService() -> NSXPCConnection {
        if let connect = BTAppXPCClient.connect {
            return connect
        }

        let connect = NSXPCConnection(serviceName: BT_SERVICE_NAME)

        connect.remoteObjectInterface = NSXPCInterface(with: BTServiceCommProtocol.self)

        connect.invalidationHandler = BTAppXPCClient.Handlers.invalidation
        connect.interruptionHandler = BTAppXPCClient.Handlers.interruption

        connect.resume()

        BTAppXPCClient.connect = connect

        os_log("XPC app connected")

        return connect
    }

    private static func getService() -> BTServiceCommProtocol? {
        let connect = BTAppXPCClient.connectService()

        guard let service = connect.remoteObjectProxyWithErrorHandler({ error in
            os_log("XPC app remote object error: \(error)")
        }) as? BTServiceCommProtocol else {
            os_log("XPC app remote object is malfored")
            return nil
        }

        return service
    }

    internal static func askAuthorization(reply: @Sendable @escaping (NSData?) -> Void) -> Void {
        guard let service = BTAppXPCClient.getService() else {
            DispatchQueue.global(qos: .userInitiated).async {
                reply(nil)
            }

            return
        }

        service.askAuthorization(reply: reply)
    }
}
