#include "SecCodeEx.h"

#include <Security/SecCode.h>

OSStatus SecCodeCopySigningInformationDynamic(SecCodeRef code, SecCSFlags flags, CFDictionaryRef * __nonnull CF_RETURNS_RETAINED information)
{
    return SecCodeCopySigningInformation(code, flags, information);
}
