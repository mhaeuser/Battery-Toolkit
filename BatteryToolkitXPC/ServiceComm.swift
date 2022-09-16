/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

internal final class BTServiceComm: NSObject, BTServiceCommProtocol {
    internal func askAuthorization(reply: @escaping ((NSData?) -> Void)) -> Void {
        var auth: AuthorizationRef? = nil
        let status = AuthorizationCreate(nil, nil, [], &auth)
        guard status == errAuthorizationSuccess, let auth = auth else {
            reply(nil)
            return
        }
        
        var extAuth = AuthorizationExternalForm()
        let extStatus = AuthorizationMakeExternalForm(auth, &extAuth)
        if extStatus != errAuthorizationSuccess {
            reply(nil)
            return
        }
        
        reply(NSData(bytes: &extAuth.bytes, length: Int(kAuthorizationExternalFormLength)))
    }
}
