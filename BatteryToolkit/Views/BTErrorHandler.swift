//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

internal enum BTErrorHandler {
    @MainActor static func errorHandler(
        error: BTError.RawValue,
        window: NSWindow? = nil
    ) {
        assert(error != BTError.success.rawValue)

        switch error {
        case BTError.notAuthorized.rawValue:
            BTAppPrompts.promptNotAuthorized(window: window)

        case BTError.commFailed.rawValue:
            BTAppPrompts.promptDaemonCommFailed(window: window)

        default:
            BTAppPrompts.promptUnexpectedError(window: window)
        }
    }

    @Sendable static func completionHandler(error: BTError.RawValue) {
        guard error != BTError.success.rawValue else {
            return
        }

        DispatchQueue.main.async {
            self.errorHandler(error: error)
        }
    }
}
