//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import IOKit
import os

import SMCParamStruct

private func packUInt32(
    _ byte0: UInt8,
    _ byte1: UInt8,
    _ byte2: UInt8,
    _ byte3: UInt8
) -> UInt32 {
    let comp0 = UInt32(byte0) << 24
    let comp1 = UInt32(byte1) << 16
    let comp2 = UInt32(byte2) << 8
    let comp3 = UInt32(byte3)

    return comp0 | comp1 | comp2 | comp3
}

private func SMCParamStructInfo(key: SMCCommKey) -> SMCParamStruct {
    var paramStruct = SMCParamStruct()
    paramStruct.key = key
    paramStruct.data8 = UInt8(kSMCGetKeyInfo)
    return paramStruct
}

private func SMCParamStructReadUI8(key: SMCCommKey) -> SMCParamStruct {
    var paramStruct = SMCParamStruct()
    paramStruct.key = key
    paramStruct.keyInfo.dataSize = 1
    paramStruct.data8 = UInt8(kSMCReadKey)
    return paramStruct
}

private func SMCParamStructWriteUI8(
    key: SMCCommKey,
    value: UInt8
) -> SMCParamStruct {
    var paramStruct = SMCParamStruct()
    paramStruct.key = key
    paramStruct.keyInfo.dataSize = 1
    paramStruct.data8 = UInt8(kSMCWriteKey)
    paramStruct.bytes.0 = value
    return paramStruct
}

private func SMCParamStructOutput() -> SMCParamStruct {
    return SMCParamStruct()
}

public typealias SMCId = FourCharCode

public extension SMCId {
    init(
        _ char0: Character,
        _ char1: Character,
        _ char2: Character,
        _ char3: Character
    ) {
        assert(char0.isASCII && char1.isASCII && char2.isASCII && char3.isASCII)

        self = packUInt32(
            char0.asciiValue!,
            char1.asciiValue!,
            char2.asciiValue!,
            char3.asciiValue!
        )
    }
}

public typealias SMCCommType = SMCId
public typealias SMCCommKey = SMCId

public extension SMCCommType {
    static let ui8 = SMCCommType("u", "i", "8", " ")
    static let hex = SMCCommType("h", "e", "x", "_")
}

public typealias SMCCommKeyInfoData = SMCKeyInfoData

extension SMCCommKeyInfoData: Equatable {
    public static func == (
        lhs: SMCCommKeyInfoData,
        rhs: SMCCommKeyInfoData
    ) -> Bool {
        return lhs.dataSize == rhs.dataSize &&
            lhs.dataType == rhs.dataType &&
            lhs.dataAttributes == rhs.dataAttributes
    }
}

public struct SMCCommKeyInfo {
    let key: SMCId
    let info: SMCCommKeyInfoData
}

public enum SMCCommError: Error {
    case invalidDataSize

    case native(kIOReturn: kern_return_t, SMCResult: UInt8)
}

@MainActor
public enum SMCComm {
    private static var connect = IO_OBJECT_NULL

    public static func start() -> Bool {
        assert(SMCComm.connect == IO_OBJECT_NULL)

        let smc = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard smc != IO_OBJECT_NULL else {
            return false
        }
        //
        // mach_task_self_ is logically immutable and thus concurrency-safe.
        //
        var connect: io_connect_t = IO_OBJECT_NULL
        let resultOpen = IOServiceOpen(
            smc,
            mach_task_self_,
            1,
            &connect
        )
        guard resultOpen == kIOReturnSuccess, connect != IO_OBJECT_NULL else {
            return false
        }

        SMCComm.connect = connect
        IOConnectCallMethod(
            connect,
            UInt32(kSMCUserClientOpen),
            nil,
            0,
            nil,
            0,
            nil,
            nil,
            nil,
            nil
        )

        return true
    }

    public static func stop() {
        assert(SMCComm.connect != IO_OBJECT_NULL)
        IOConnectCallMethod(
            SMCComm.connect,
            UInt32(kSMCUserClientClose),
            nil,
            0,
            nil,
            0,
            nil,
            nil,
            nil,
            nil
        )
        IOServiceClose(SMCComm.connect)
        SMCComm.connect = IO_OBJECT_NULL
    }

    private static func callSMCFunctionYPC(
        params: inout SMCParamStruct
    ) throws -> SMCParamStruct {
        assert(SMCComm.connect != IO_OBJECT_NULL)

        assert(MemoryLayout<SMCParamStruct>.stride == 80)

        var outputValues = SMCParamStructOutput()
        var outStructSize = MemoryLayout<SMCParamStruct>.stride

        let resultCall = IOConnectCallStructMethod(
            SMCComm.connect,
            UInt32(kSMCHandleYPCEvent),
            &params,
            MemoryLayout<SMCParamStruct>.stride,
            &outputValues,
            &outStructSize
        )
        guard
            resultCall == kIOReturnSuccess,
            outputValues.result == UInt8(kSMCSuccess)
        else {
            throw SMCCommError.native(
                kIOReturn: resultCall,
                SMCResult: outputValues.result
            )
        }

        return outputValues
    }

    public static func GetKeyInfo(key: SMCCommKey) throws
        -> SMCCommKeyInfoData
    {
        var inputStruct = SMCParamStructInfo(key: key)

        let outputStruct = try callSMCFunctionYPC(params: &inputStruct)

        return outputStruct.keyInfo
    }

    public static func ReadKeyUI8(key: SMCCommKey) throws -> UInt8 {
        var inputStruct = SMCParamStructReadUI8(key: key)

        let outputStruct = try callSMCFunctionYPC(params: &inputStruct)

        return outputStruct.bytes.0
    }

    public static func WriteKeyUI8(key: SMCCommKey, value: UInt8) throws {
        var inputStruct = SMCParamStructWriteUI8(key: key, value: value)

        _ = try self.callSMCFunctionYPC(params: &inputStruct)
    }
}
