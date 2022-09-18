/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

public struct CSIdentification {
    public static func getUniqueId(staticCode: SecStaticCode) -> NSData? {
        var signInfo: CFDictionary? = nil
        let infoStatus = SecCodeCopySigningInformation(
            staticCode,
            [],
            &signInfo
            )
        if infoStatus != errSecSuccess {
            os_log("Failed to retrieve signing information")
            return nil
        }

        guard let signInfo = signInfo as? [String: AnyObject] else {
            os_log("Signing information is nil")
            return nil
        }

        guard let unique = signInfo[kSecCodeInfoUnique as String] as? NSData else {
            os_log("Unique identifier is invalid")
            return nil
        }

        return unique
    }

    public static func getUniqueIdSelf() -> NSData? {
        var code: SecCode? = nil
        let selfStatus = SecCodeCopySelf([], &code)
        guard selfStatus == errSecSuccess, let code = code else {
            return nil
        }

        var staticCode: SecStaticCode? = nil
        let staticStatus = SecCodeCopyStaticCode(code, [], &staticCode)
        guard staticStatus == errSecSuccess, let staticCode = staticCode else {
            os_log("Failed to retrieve SecStaticCode")
            return nil
        }

        return CSIdentification.getUniqueId(staticCode: staticCode)
    }

    public static func getBundleRelativeUniqueId(relative: String) -> NSData? {
        let pathURL = Bundle.main.bundleURL.appendingPathComponent(relative)
        var staticCode: SecStaticCode? = nil
        let status = SecStaticCodeCreateWithPath(
            pathURL as CFURL,
            [],
            &staticCode
            )
        guard status == errSecSuccess, let staticCode = staticCode else {
            os_log("Failed to retrieve SecStaticCode")
            return nil
        }

        return CSIdentification.getUniqueId(staticCode: staticCode)
    }
}
