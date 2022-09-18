/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

public struct BTLocalization {
    public struct Prompts {
        public static let approve = NSLocalizedString(
            "Approve",
            comment: "Prompt button to approve an action"
            )

        public static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Prompt button to cancel an action"
            )

        public static let retry = NSLocalizedString(
            "Retry",
            comment: "Prompt button to retry an action"
            )

        public static let quit = NSLocalizedString(
            "Quit",
            comment: "Prompt button to quit the app"
            )

        public static let disableAndQuit = NSLocalizedString(
            "Disable and Quit",
            comment: "Prompt button to disable a core function and quit the app"
            )

        public struct Daemon {
            public static let requiredInfo = NSLocalizedString(
                "To manage the power state of your Mac, Battery Toolkit needs to run in the background.",
                comment: "Prompt text explaining the requirement for background activity"
            )

            public static let allowMessage = NSLocalizedString(
                "Allow background activity?",
                comment: "Prompt caption asking to allow background activity"
                )

            public static let allowInfo = NSLocalizedString(
                "Do you want to approve the Battery Toolkit Login Item in System Settings?",
                comment: "Prompt text asking to approve background activity"
                )

            public static let enableFailMessage = NSLocalizedString(
                "Failed to enable background activity.",
                comment: "Prompt caption informing of failure to enable background activity"
                )

            public static let disableMessage = NSLocalizedString(
                "Disable background activity?",
                comment: "Prompt caption asking whether to disable background activity"
                )

            public static let disableInfo = NSLocalizedString(
                "Do you want to disable background activity for Battery Toolkit?",
                comment: "Prompt text asking whether to disable background activity"
                )

            public static let disableFailMessage = NSLocalizedString(
                "An error occurred disabling background activity.",
                comment: "Prompt caption informing of failure to disable background activity"
                )
        }
    }

    public static let preferences = NSLocalizedString(
        "Preferences",
        comment: "Preferences for macOS 12 and below"
        )
}
