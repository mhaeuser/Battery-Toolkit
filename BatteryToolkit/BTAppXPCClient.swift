//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log
import ServiceManagement

@BTBackgroundActor
internal enum BTAppXPCClient {
    private static var connect: NSXPCConnection? = nil

    static func getAuthorization() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let service = self.getService {
                continuation.resume(throwing: BTError.commFailed)
            }
            
            service.getAuthorization { data in
                guard let data = data else {
                    continuation.resume(throwing: BTError.notAuthorized)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }

    static func getDaemonAuthorization() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let service = self.getService {
                continuation.resume(throwing: BTError.commFailed)
            }
            
            service.getDaemonAuthorization { data in
                guard let data = data else {
                    continuation.resume(throwing: BTError.notAuthorized)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }

    static func getManageAuthorization() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let service = self.getService {
                continuation.resume(throwing: BTError.commFailed)
            }
            
            service.getManageAuthorization { data in
                guard let data = data else {
                    continuation.resume(throwing: BTError.notAuthorized)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }

    private nonisolated static func interruptionHandler() {
        os_log("XPC app connection interrupted")
    }

    private nonisolated static func invalidationHandler() {
        Task { @BTBackgroundActor in
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
            os_log("XPC app remote object error: \(error, privacy: .public))")
            errorHandler()
        } as! BTServiceCommProtocol

        return service
    }
}
