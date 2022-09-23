/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa

@MainActor
internal struct BTAppPrompts {
    private static func unregisterDaemon() {
        BatteryToolkit.unregisterDaemon() { (success) -> Void in
            DispatchQueue.main.async {
                guard success else {
                    promptUnregisterDaemonError()
                    return
                }

                NSApp.terminate(self)
            }
        }
    }

    internal static func promptApproveDaemon(timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.allowMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.allowInfo
        alert.alertStyle      = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.approve)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = alert.runModal()
        switch response {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                BatteryToolkit.approveDaemon(timeout: timeout, reply: reply)

            case NSApplication.ModalResponse.alertSecondButtonReturn:
                NSApp.terminate(self)

            default:
                assert(false)
        }
    }

    internal static func promptRegisterDaemonError() -> Bool {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.enableFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo
        alert.alertStyle      = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = alert.runModal()
        switch response {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                return true

            case NSApplication.ModalResponse.alertSecondButtonReturn:
                NSApp.terminate(self)

            default:
                assert(false)
        }

        return false
    }

    internal static func promptUnregisterDaemon() {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.disableMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
        "\n\n" + BTLocalization.Prompts.Daemon.disableInfo
        alert.alertStyle      = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            unregisterDaemon()
        }
    }

    internal static func promptUnregisterDaemonError() {
        let alert         = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle  = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            unregisterDaemon()
        }
    }
}
