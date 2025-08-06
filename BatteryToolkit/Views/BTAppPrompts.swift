//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import ServiceManagement

@MainActor
internal enum BTAppPrompts {
    private(set) static var open: UInt8 = 0

    static func promptQuit() {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.quitMessage
        if #available(macOS 13.0, *) {
            alert.informativeText = BTLocalization.Prompts.quitInfo + " " + BTLocalization.Prompts.quitInfoMacOS13
        } else {
            alert.informativeText = BTLocalization.Prompts.quitInfo
        }
        alert.alertStyle = NSAlert.Style.informational
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        if #available(macOS 13.0, *) {
            _ = alert.addButton(withTitle: BTLocalization.Prompts.openSystemSettings)
        }
        let response = self.runPromptStandalone(alert: alert)
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            NSApp.terminate(self)
            
        case NSApplication.ModalResponse.alertSecondButtonReturn:
            break
            
        case NSApplication.ModalResponse.alertThirdButtonReturn:
            if #available(macOS 13.0, *) {
                SMAppService.openSystemSettingsLoginItems()
            } else {
                assertionFailure()
            }
            break

        default:
            assertionFailure()
        }
    }

    static func promptApproveDaemon(timeout: UInt8) async throws {
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
            try await BTActions.approveDaemon(timeout: timeout)

        case NSApplication.ModalResponse.alertSecondButtonReturn:
            NSApp.terminate(self)

        default:
            assertionFailure()
        }
    }

    static func promptMachineUnsupported() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.unsupportedMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.unsupportedInfo
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = self.runPromptStandalone(alert: alert)
        await self.forceRemoveDaemon()
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

    static func promptRemoveDaemon() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.disableInfo
        alert.alertStyle = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryRemoveDaemon()
        }
    }

    static func promptTryRemoveDaemonError() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.tryRemoveDaemon()
        }
    }

    static func promptForceRemoveDaemonError() async {
        let alert = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = self.runPromptStandalone(alert: alert)
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            await self.forceRemoveDaemon()
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
        Task {
            let alert = NSAlert()
            alert.messageText = BTLocalization.Prompts.Daemon.commFailMessage
            alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.commFailInfo
            alert.alertStyle = NSAlert.Style.critical
            _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
            let _ = await self.runPrompt(alert: alert, window: window)
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

    private static func tryRemoveDaemon() async {
        do {
            try await BTActions.removeDaemon()
            self.cleanupAndTerminate()
        } catch {
            await self.promptTryRemoveDaemonError()
        }
    }

    private static func forceRemoveDaemon() async {
        do {
            try await BTActions.removeDaemon()
            self.cleanupAndTerminate()
        } catch {
            await self.promptForceRemoveDaemonError()
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

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil) async -> NSApplication.ModalResponse {
        guard let window else {
            return self.runPromptStandalone(alert: alert)
        }

        return await alert.beginSheetModal(for: window)
    }

    private static func runPrompt(alert: NSAlert, window: NSWindow? = nil) {
        Task {
            await self.runPrompt(alert: alert, window: window)
        }
    }
}
