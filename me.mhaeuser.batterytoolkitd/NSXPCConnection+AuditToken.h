//
//  NSXPCConnection+AuditToken.h
//  com.smjobblesssample.installer
//
//  Created by aronskaya on 07.06.2020.
//

@import Foundation;

@interface NSXPCConnection (AuditToken)

// Apple uses this property internally to verify XPC connections.
// There is no safe pulicly available alternative (check by client pid, for example, is racy)
@property (nonatomic, readonly) audit_token_t auditToken;

@end
