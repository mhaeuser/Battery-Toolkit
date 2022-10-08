//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

import BTPreprocessor
import NSXPCConnectionAuditToken
import Security

internal enum BTDaemonXPCServer {
    @MainActor private static let listener = NSXPCListener(
        machServiceName: BT_DAEMON_ID
    )

    private static let delegate: NSXPCListenerDelegate = Delegate()

    private static let daemonInterface =
        NSXPCInterface(with: BTDaemonCommProtocol.self)
    private static let daemonComm = BTDaemonComm()

    @MainActor static func start() {
        self.listener.delegate = self.delegate
        self.listener.resume()
    }
}

private extension BTDaemonXPCServer {
    final class Delegate: NSObject, NSXPCListenerDelegate {
        func listener(
            _: NSXPCListener,
            shouldAcceptNewConnection newConnection: NSXPCConnection
        ) -> Bool {
            guard BTXPCValidation.isValidClient(connection: newConnection)
            else {
                os_log("XPC server connection by invalid client")
                return false
            }

            newConnection.exportedInterface = BTDaemonXPCServer.daemonInterface
            newConnection.exportedObject = BTDaemonXPCServer.daemonComm

            newConnection.resume()

            return true
        }
    }
}
