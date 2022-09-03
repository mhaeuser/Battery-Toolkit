@import Foundation;

//
// REF: https://blog.obdev.at/what-we-have-learned-from-a-vulnerability/index.html
//

@interface NSXPCConnection (AuditToken)

// This property exists, but it's private. Make it available:
@property (nonatomic, readonly) audit_token_t auditToken;

@end
