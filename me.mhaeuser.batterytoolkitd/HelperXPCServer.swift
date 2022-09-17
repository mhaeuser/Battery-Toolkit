/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

import BTPreprocessor
import NSXPCConnectionAuditToken
import Security

internal struct BTHelperXPCServer {
    private final class Delegate: NSObject, NSXPCListenerDelegate {
        fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
            return BTHelperXPCServer.accept(newConnection: newConnection)
        }
    }

    @MainActor private static var listener: NSXPCListener = NSXPCListener(machServiceName: BT_DAEMON_NAME)

    private static let delegate: NSXPCListenerDelegate = BTHelperXPCServer.Delegate()
    
    @MainActor internal static func start() {
        listener.delegate = delegate
        listener.resume()
    }
    
    private static func accept(newConnection: NSXPCConnection) -> Bool {
        if !BTXPCValidation.isValidClient(connection: newConnection) {
            os_log("XPC server connection by invalid client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: BTHelperCommProtocol.self)
        newConnection.exportedObject    = BTHelperComm()
        
        newConnection.resume()
        
        return true
    }
}
