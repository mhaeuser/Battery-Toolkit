//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

@MainActor
internal enum BTAppXPCClient {
    private enum Handlers {
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

        connect.remoteObjectInterface = NSXPCInterface(
            with: BTServiceCommProtocol.self
        )

        connect.invalidationHandler = BTAppXPCClient.Handlers.invalidation
        connect.interruptionHandler = BTAppXPCClient.Handlers.interruption

        BTXPCValidation.protectService(connection: connect)

        connect.resume()

        BTAppXPCClient.connect = connect

        os_log("XPC app connected")

        return connect
    }

    private static func getService(errorHandler: @escaping @Sendable () -> Void)
        -> BTServiceCommProtocol
    {
        let connect = BTAppXPCClient.connectService()

        let service = connect.remoteObjectProxyWithErrorHandler { error in
            os_log("XPC app remote object error: \(error.localizedDescription)")
            errorHandler()
        } as! BTServiceCommProtocol

        return service
    }

    internal static func createEmptyAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let service = BTAppXPCClient.getService {
            reply(nil)
        }

        service.createEmptyAuthorization(reply: reply)
    }

    internal static func createDaemonAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let service = BTAppXPCClient.getService {
            reply(nil)
        }

        service.createDaemonAuthorization(reply: reply)
    }

    internal static func createManageAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let service = BTAppXPCClient.getService {
            reply(nil)
        }

        service.createManageAuthorization(reply: reply)
    }
}
