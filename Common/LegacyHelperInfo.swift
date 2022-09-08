import Foundation
import BTPreprocessor

public struct BTLegacyHelperInfo {
    public static let legacyHelperExec  = "/Library/PrivilegedHelperTools/\(BTPreprocessor.BT_DAEMON_NAME)"
    public static let legacyHelperPlist = "/Library/LaunchDaemons/\(BTPreprocessor.BT_DAEMON_NAME).plist"
}
