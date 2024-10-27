//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal enum BTLocalization {
    enum Prompts {
        static let ok = NSLocalizedString(
            "OK",
            comment: "Prompt button to acknowledge a situation"
        )

        static let approve = NSLocalizedString(
            "Approve",
            comment: "Prompt button to approve an action"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Prompt button to cancel an action"
        )

        static let retry = NSLocalizedString(
            "Retry",
            comment: "Prompt button to retry an action"
        )

        static let quit = NSLocalizedString(
            "Quit",
            comment: "Prompt button to quit the app"
        )

        static let disableAndQuit = NSLocalizedString(
            "Disable and Quit",
            comment: "Prompt button to disable a core function and quit the app"
        )

        static let openSystemSettings = NSLocalizedString(
            "Open System Settings",
            comment: "Prompt button to open System Settings"
        )

        static let quitMessage = NSLocalizedString(
            "Quit Battery Toolkit?",
            comment: "Prompt caption asking whether to quit the app"
        )

        static let quitInfo = NSLocalizedString(
            "Battery Toolkit will continue to run in the background. To permanently suspend it, disable the background activity from the Battery Toolkit menu.",
            comment: "Prompt caption asking whether to quit the app"
        )

        static let quitInfoMacOS13 = NSLocalizedString(
            "To temporarily suspend it, disable the background activity in System Settings.",
            comment: "Prompt caption asking whether to quit the app"
        )

        static let unexpectedErrorMessage = NSLocalizedString(
            "An unexpected error has occured.",
            comment: "Prompt caption informing the user of an unexpected error"
        )

        static let notAuthorizedMessage = NSLocalizedString(
            "You do not have permission to perform this operation.",
            comment: "Prompt caption informing the user that they are not authorized to perform a specific operation"
        )

        enum Daemon {
            static let requiredInfo = NSLocalizedString(
                "To manage the power state of your Mac, Battery Toolkit needs to run in the background.",
                comment: "Prompt text explaining the requirement for background activity"
            )

            static let allowMessage = NSLocalizedString(
                "Allow background activity?",
                comment: "Prompt caption asking to allow background activity"
            )

            static let allowInfo = NSLocalizedString(
                "Do you want to approve the Battery Toolkit Login Item in System Settings?",
                comment: "Prompt text asking to approve background activity"
            )

            static let enableFailMessage = NSLocalizedString(
                "Failed to enable background activity.",
                comment: "Prompt caption informing of failure to enable background activity"
            )

            static let disableMessage = NSLocalizedString(
                "Disable background activity?",
                comment: "Prompt caption asking whether to disable background activity"
            )

            static let disableInfo = NSLocalizedString(
                "Do you want to disable background activity for Battery Toolkit?",
                comment: "Prompt text asking whether to disable background activity"
            )

            static let disableFailMessage = NSLocalizedString(
                "An error occurred disabling background activity.",
                comment: "Prompt caption informing of failure to disable background activity"
            )

            static let commFailMessage = NSLocalizedString(
                "Failed to communicate with the background service.",
                comment: "Prompt caption informing the user that the app failed to communicate with its background service"
            )

            static let commFailInfo = NSLocalizedString(
                "Please restart your Mac and try again. If the problem persists, contact the developers.",
                comment: "Prompt text instructing the user to restart the machine and try again"
            )

            static let unsupportedMessage = NSLocalizedString(
                "Your Mac is not supported.",
                comment: "Prompt caption informing the user that the app does not support this machine"
            )

            static let unsupportedInfo = NSLocalizedString(
                "Battery Toolkit does not support managing the power state of your Mac. Background activity will be disabled.",
                comment: "Prompt text informing the user the app does not support this machine and that background activity will be disabled in response"
            )
        }
    }

    static let preferences = NSLocalizedString(
        "Preferences",
        comment: "Preferences for macOS 12 and below"
    )
}
