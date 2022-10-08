//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal enum BTAppPrompts {
    private(set) static var open: UInt8 = 0

    static func promptApproveDaemon(
        timeout: UInt8,
        reply: @escaping @Sendable (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.allowMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.allowInfo
        alert.alertStyle = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.approve)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            BTActions.approveDaemon(timeout: timeout, reply: reply)

        case NSApplication.ModalResponse.alertSecondButtonReturn:
            NSApp.terminate(self)

        default:
            assertionFailure()
        }
    }

    static func promptMachineUnsupported() {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.unsupportedMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.unsupportedInfo
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = self.runPromptStandalone(alert: alert)
        self.forceRemoveDaemon()
    }

    static func promptRegisterDaemonError() -> Bool {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.enableFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            return true

        case NSApplication.ModalResponse.alertSecondButtonReturn:
            NSApp.terminate(self)

        default:
            assertionFailure()
        }

        return false
    }

    static func promptRemoveDaemon() {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.disableInfo
        alert.alertStyle = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            self.tryRemoveDaemon()
        }
    }

    static func promptTryRemoveDaemonError() {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            self.tryRemoveDaemon()
        }
    }

    static func promptForceRemoveDaemonError() {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            self.forceRemoveDaemon()
            return
        }

        self.cleanupAndTerminate()
    }

    static func promptUnexpectedError(window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.unexpectedErrorMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        self.runPrompt(alert: alert, window: window)
    }

    static func promptNotAuthorized(window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.notAuthorizedMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.ok)
        self.runPrompt(alert: alert, window: window)
    }

    static func promptDaemonCommFailed(window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.commFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.commFailInfo
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        self.runPrompt(alert: alert, window: window) { _ in
            assert(Thread.isMainThread)
            NSApp.terminate(self)
        }
    }

    private static func cleanupAndTerminate() {
        _ = BTLoginItem.disable()

        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }

        NSApp.terminate(nil)
    }

    private static func tryRemoveDaemon() {
        BTActions.removeDaemon { error in
            DispatchQueue.main.async {
                guard error == BTError.success.rawValue else {
                    promptTryRemoveDaemonError()
                    return
                }

                cleanupAndTerminate()
            }
        }
    }

    private static func forceRemoveDaemon() {
        BTActions.removeDaemon { error in
            DispatchQueue.main.async {
                guard error == BTError.success.rawValue else {
                    promptForceRemoveDaemonError()
                    return
                }

                cleanupAndTerminate()
            }
        }
    }

    private static func runPromptStandalone(alert: NSAlert) -> NSApplication
        .ModalResponse
    {
        self.open += 1
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        self.open -= 1

        return response
    }

    private static func runPrompt(
        alert: NSAlert,
        window: NSWindow? = nil,
        reply: @MainActor @escaping @Sendable (NSApplication.ModalResponse)
            -> Void
    ) {
        guard let window else {
            let response = self.runPromptStandalone(alert: alert)
            reply(response)
            return
        }
        //
        // The warning about losing MainActor is misleading because
        // completionHandler is always executed on the main thread.
        //
        alert.beginSheetModal(for: window, completionHandler: reply)
    }

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil) {
        self.runPrompt(alert: alert, window: window) { _ in }
    }
}
