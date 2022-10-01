/*
 * Copyright (c) 2003 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef _SMCParamStruct_h_
#define _SMCParamStruct_h_

#include <stdint.h>

#include <IOKit/IOTypes.h>
#include <IOKit/IOKitLib.h>

__BEGIN_DECLS

// Todo: verify kSMCKeyNotFound
enum {
    kSMCKeyNotFound = 0x84
};

/* Do not modify - defined by AppleSMC.kext */
enum {
    kSMCSuccess    = 0,
    kSMCError    = 1
};
enum {
    kSMCUserClientOpen  = 0,
    kSMCUserClientClose = 1,
    kSMCHandleYPCEvent  = 2,
    kSMCReadKey         = 5,
    kSMCWriteKey        = 6,
    kSMCGetKeyCount     = 7,
    kSMCGetKeyFromIndex = 8,
    kSMCGetKeyInfo      = 9
};
/* Do not modify - defined by AppleSMC.kext */
typedef struct SMCVersion
{
    unsigned char    major;
    unsigned char    minor;
    unsigned char    build;
    unsigned char    reserved;
    unsigned short   release;
    
} SMCVersion;
/* Do not modify - defined by AppleSMC.kext */
typedef struct SMCPLimitData
{
    uint16_t    version;
    uint16_t    length;
    uint32_t    cpuPLimit;
    uint32_t    gpuPLimit;
    uint32_t    memPLimit;

} SMCPLimitData;
/* Do not modify - defined by AppleSMC.kext */
typedef struct SMCKeyInfoData
{
    //IOByteCount         dataSize;
    uint32_t            dataSize;
    uint32_t            dataType;
    uint8_t             dataAttributes;

} SMCKeyInfoData;
/* Do not modify - defined by AppleSMC.kext */
typedef struct {
    uint32_t            key;
    SMCVersion          vers;
    SMCPLimitData       pLimitData;
    SMCKeyInfoData      keyInfo;
    uint8_t             result;
    uint8_t             status;
    uint8_t             data8;
    uint32_t            data32;
    uint8_t             bytes[32];
}  SMCParamStruct;

__END_DECLS

#endif /* SMCParamStruct_h */
