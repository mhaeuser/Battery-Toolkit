/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa
import os.log

/// Autostart Helper app that quietly starts its containing application.
@main
private struct AutostartHelper {
    /// Start the containing app quietly.
    private static func main() {
        //
        // Ensure this helper is launched from an expected location.
        //
        let pathComponents = Bundle.main.bundleURL.pathComponents
        guard pathComponents.count >= 4 &&
                pathComponents[pathComponents.count - 4] == "Contents" &&
                pathComponents[pathComponents.count - 3] == "Library" &&
                pathComponents[pathComponents.count - 2] == "LoginItems" else {
            os_log("Unexpected bundle URL: \(pathComponents, privacy: .public)")
            return
        }
        //
        // Retrieve the URL of the containing app.
        //
        var mainAppPath = Bundle.main.bundleURL
        for _ in 0 ... 3 {
            mainAppPath = mainAppPath.deletingLastPathComponent()
        }
        //
        // Start the containing app quietly.
        //
        let config = NSWorkspace.OpenConfiguration()
        config.promptsUserIfNeeded                  = false
        config.addsToRecentItems                    = false
        config.activates                            = false
        config.allowsRunningApplicationSubstitution = false

        os_log("Launching URL: \(mainAppPath, privacy: .public)")
        NSWorkspace.shared.openApplication(
            at: mainAppPath,
            configuration: config
            ) { _, error in
            os_log("Launch result: \(error?.localizedDescription ?? "success", privacy: .public)")
            exit(0)
        }
        //
        // Start dispatching the main queue to run the completion handler above.
        //
        dispatchMain()
    }
}
