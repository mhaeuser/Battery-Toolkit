//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal enum BTAccessoryMode {
    private static var accessory = false
    private static var ignoreCall = false

    private static func inactivateApp() {
        //
        // Force the current app to become inactive by activating Dock. Dock
        // should always be running and cause no visual issues from being
        // activated.
        //
        let dockApps = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.dock"
        )
        guard !dockApps.isEmpty else {
            return
        }

        dockApps[0].activate(options: .activateIgnoringOtherApps)
    }

    internal static func activate() {
        guard !BTAccessoryMode.accessory, !BTAccessoryMode.ignoreCall else {
            return
        }

        guard NSApp.keyWindow == nil, BTAppPrompts.open == 0 else {
            return
        }

        BTAccessoryMode.accessory = true
        _ = NSApp.setActivationPolicy(.accessory)
    }

    internal static func deactivate() {
        guard BTAccessoryMode.accessory, !BTAccessoryMode.ignoreCall else {
            return
        }

        BTAccessoryMode.accessory = false
        //
        // As we trigger the current app to re-activate, ignore requests from
        // BecomeActive and ResignActive handlers.
        //
        BTAccessoryMode.ignoreCall = true

        _ = NSApp.setActivationPolicy(.regular)
        //
        // Re-activate the app because otherwise the menu bar will not respond
        // to interaction.
        //
        self.inactivateApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            BTAccessoryMode.ignoreCall = false
        }
    }
}
