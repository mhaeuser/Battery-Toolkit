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
    private static var connect: NSXPCConnection? = nil

    static func getAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let service = self.getService {
            reply(nil)
        }

        service.getAuthorization(reply: reply)
    }

    static func getDaemonAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let service = self.getService {
            reply(nil)
        }

        service.getDaemonAuthorization(reply: reply)
    }

    static func getManageAuthorization(
        reply: @Sendable @escaping (Data?) -> Void
    ) {
        let service = self.getService {
            reply(nil)
        }

        service.getManageAuthorization(reply: reply)
    }

    private nonisolated static func interruptionHandler() {
        os_log("XPC app connection interrupted")
    }

    private nonisolated static func invalidationHandler() {
        DispatchQueue.main.async {
            BTAppXPCClient.connect = nil
        }

        os_log("XPC app connection invalidated")
    }

    private static func connectService() -> NSXPCConnection {
        if let connect = self.connect {
            return connect
        }

        let connect = NSXPCConnection(serviceName: BT_SERVICE_ID)

        connect.remoteObjectInterface = NSXPCInterface(
            with: BTServiceCommProtocol.self
        )

        connect.invalidationHandler = self.invalidationHandler
        connect.interruptionHandler = self.interruptionHandler

        BTXPCValidation.protectService(connection: connect)

        connect.resume()

        self.connect = connect

        os_log("XPC app connected")

        return connect
    }

    private static func getService(errorHandler: @escaping @Sendable () -> Void)
        -> BTServiceCommProtocol
    {
        let connect = self.connectService()

        let service = connect.remoteObjectProxyWithErrorHandler { error in
            os_log("XPC app remote object error: \(error)")
            errorHandler()
        } as! BTServiceCommProtocol

        return service
    }
}
