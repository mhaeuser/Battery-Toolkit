/*@file
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

@import Foundation;

//
// REF: https://blog.obdev.at/what-we-have-learned-from-a-vulnerability/index.html
//

@interface NSXPCConnection (AuditToken)

@property (nonatomic, readonly) audit_token_t auditToken;

@end
