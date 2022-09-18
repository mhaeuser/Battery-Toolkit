/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

internal struct BTServiceXPCServer {
    private final class Delegate: NSObject, NSXPCListenerDelegate {
        fileprivate func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
            return BTServiceXPCServer.accept(newConnection: newConnection)
        }
    }

    private static let delegate = BTServiceXPCServer.Delegate()
    private static let listener = NSXPCListener.service()

    private static func accept(newConnection: NSXPCConnection) -> Bool {
        guard BTXPCValidation.isValidClient(connection: newConnection) else {
            os_log("XPC service connection by invalid client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: BTServiceCommProtocol.self)
        newConnection.exportedObject    = BTServiceComm()
        
        newConnection.resume()
        
        return true
    }
    
    internal static func start() {
        listener.delegate = delegate
        listener.resume()
    }
}
