/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

internal struct BTCompletionHandlers {
    @Sendable internal static func commandError(error: BTError.RawValue) {
        guard error != BTError.success.rawValue else {
            return
        }

        DispatchQueue.main.async {
            switch error {
                case BTError.notAuthorized.rawValue:
                    BTAppPrompts.promptNotAuthorized()

                default:
                    BTAppPrompts.promptUnexpectedError()
            }
        }
    }
}
