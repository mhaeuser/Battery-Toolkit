#ifndef _SecCodeEx_h_
#define _SecCodeEx_h_

#include <Security/CSCommon.h>

__BEGIN_DECLS

OSStatus SecCodeCopySigningInformationDynamic(SecCodeRef code, SecCSFlags flags, CFDictionaryRef * __nonnull CF_RETURNS_RETAINED information);

__END_DECLS

#endif
