//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTServiceXPCServer {
    private static let delegate = BTServiceXPCServer.Delegate()
    private static let listener = NSXPCListener.service()

    static func start() {
        self.listener.delegate = self.delegate
        self.listener.resume()
    }
}

private extension BTServiceXPCServer {
    final class Delegate: NSObject, NSXPCListenerDelegate {
        func listener(
            _: NSXPCListener,
            shouldAcceptNewConnection newConnection: NSXPCConnection
        ) -> Bool {
            guard BTXPCValidation.isValidClient(connection: newConnection)
            else {
                os_log("XPC service connection by invalid client")
                return false
            }

            newConnection.exportedInterface = NSXPCInterface(
                with: BTServiceCommProtocol.self
            )
            newConnection.exportedObject = BTServiceComm()

            newConnection.resume()

            return true
        }
    }
}
