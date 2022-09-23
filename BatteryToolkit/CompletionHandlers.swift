/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

internal struct BTCompletionHandlers {
    @Sendable internal static func commandError(success: Bool) {
        if !success {
            DispatchQueue.main.async {
                BTAppPrompts.promptUnexpectedError()
            }
        }
    }
}
