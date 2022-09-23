//
//  SettingsMenuItem.swift
//  BatteryToolkit
//
//  Created by User on 23.09.22.
//

import AppKit

internal final class SettingsMenuItem: NSMenuItem {
    override var title: String {
        get {
            guard #available(macOS 13.0, *) else {
                return BTLocalization.preferences + "..."
            }

            return super.title
        }

        set {
            super.title = newValue
        }
    }
}
