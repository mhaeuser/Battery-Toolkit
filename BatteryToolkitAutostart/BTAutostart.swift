/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa
import os.log

@main
private struct BTAutostart {
    private static func main() {
        let pathComponents = Bundle.main.bundleURL.pathComponents
        guard pathComponents.count >= 4 &&
                pathComponents[pathComponents.count - 4] == "Contents" &&
                pathComponents[pathComponents.count - 3] == "Library" &&
                pathComponents[pathComponents.count - 2] == "LoginItems" else {
            os_log("Unexpected bundle URL: \(pathComponents, privacy: .public)")
            return
        }

        var mainAppPath = Bundle.main.bundleURL
        for _ in 0 ... 3 {
            mainAppPath = mainAppPath.deletingLastPathComponent()
        }

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

        dispatchMain()
    }
}
