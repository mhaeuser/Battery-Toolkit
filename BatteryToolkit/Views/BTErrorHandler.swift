//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

internal enum BTErrorHandler {
    @MainActor static func errorHandler(
        error: any Error,
        window: NSWindow? = nil
    ) {
        guard let error = error as? BTError else {
            assert(false)
            self.errorHandler(error: BTError.unknown, window: window)
            return
        }

        assert(error != BTError.success)

        switch error {
        case BTError.notAuthorized:
            BTAppPrompts.promptNotAuthorized(window: window)

        case BTError.commFailed:
            BTAppPrompts.promptDaemonCommFailed(window: window)

        default:
            BTAppPrompts.promptUnexpectedError(window: window)
        }
    }
}
