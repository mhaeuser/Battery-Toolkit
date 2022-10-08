//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import IOKit
import os

import SMCParamStruct

public typealias SMCId = FourCharCode

public extension SMCId {
    init(
        _ char0: Character,
        _ char1: Character,
        _ char2: Character,
        _ char3: Character
    ) {
        assert(char0.isASCII && char1.isASCII && char2.isASCII && char3.isASCII)

        let comp0 = UInt32(char0.asciiValue!) << 24
        let comp1 = UInt32(char1.asciiValue!) << 16
        let comp2 = UInt32(char2.asciiValue!) << 8
        let comp3 = UInt32(char3.asciiValue!)

        self = comp0 | comp1 | comp2 | comp3
    }
}

public extension SMCComm {
    typealias Key = SMCId
    typealias KeyType = SMCId

    typealias KeyInfoData = SMCKeyInfoData

    struct KeyInfo {
        let key: SMCComm.Key
        let info: SMCComm.KeyInfoData
    }

    enum KeyTypes {
        static let ui8 = SMCComm.KeyType("u", "i", "8", " ")
        static let hex = SMCComm.KeyType("h", "e", "x", "_")
    }
}

extension SMCComm.KeyInfoData: Equatable {
    public static func == (
        lhs: SMCComm.KeyInfoData,
        rhs: SMCComm.KeyInfoData
    ) -> Bool {
        return lhs.dataSize == rhs.dataSize &&
            lhs.dataType == rhs.dataType &&
            lhs.dataAttributes == rhs.dataAttributes
    }
}

@MainActor
public enum SMCComm {
    private static var connect = IO_OBJECT_NULL

    static func start() -> Bool {
        assert(self.connect == IO_OBJECT_NULL)

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

        self.connect = connect
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

    static func stop() {
        assert(self.connect != IO_OBJECT_NULL)
        IOConnectCallMethod(
            self.connect,
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
        IOServiceClose(self.connect)
        self.connect = IO_OBJECT_NULL
    }

    static func getKeyInfo(key: SMCComm.Key)
        -> SMCComm.KeyInfoData?
    {
        var inputStruct = SMCParamStruct.info(key: key)

        let outputStruct = self.callSMCFunctionYPC(params: &inputStruct)
        guard let outputStruct else {
            return nil
        }

        return outputStruct.keyInfo
    }

    static func readKeyUI8(key: SMCComm.Key) -> UInt8? {
        var inputStruct = SMCParamStruct.readUI8(key: key)

        let outputStruct = self.callSMCFunctionYPC(params: &inputStruct)
        guard let outputStruct else {
            return nil
        }

        return outputStruct.bytes.0
    }

    static func writeKeyUI8(key: SMCComm.Key, value: UInt8) -> Bool {
        var inputStruct = SMCParamStruct.writeUI8(key: key, value: value)

        let outputStruct = self.callSMCFunctionYPC(params: &inputStruct)
        return outputStruct != nil
    }

    private static func callSMCFunctionYPC(
        params: inout SMCParamStruct
    ) -> SMCParamStruct? {
        assert(self.connect != IO_OBJECT_NULL)

        assert(MemoryLayout<SMCParamStruct>.stride == 80)

        var outputValues = SMCParamStruct.output()
        var outStructSize = MemoryLayout<SMCParamStruct>.stride

        let resultCall = IOConnectCallStructMethod(
            self.connect,
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
            os_log("SMC error: \(resultCall), \(outputValues.result)")
            return nil
        }

        return outputValues
    }
}

private extension SMCParamStruct {
    static func info(key: SMCComm.Key) -> SMCParamStruct {
        var paramStruct = SMCParamStruct()
        paramStruct.key = key
        paramStruct.data8 = UInt8(kSMCGetKeyInfo)
        return paramStruct
    }

    static func readUI8(key: SMCComm.Key) -> SMCParamStruct {
        var paramStruct = SMCParamStruct()
        paramStruct.key = key
        paramStruct.keyInfo.dataSize = 1
        paramStruct.data8 = UInt8(kSMCReadKey)
        return paramStruct
    }

    static func writeUI8(
        key: SMCComm.Key,
        value: UInt8
    ) -> SMCParamStruct {
        var paramStruct = SMCParamStruct()
        paramStruct.key = key
        paramStruct.keyInfo.dataSize = 1
        paramStruct.data8 = UInt8(kSMCWriteKey)
        paramStruct.bytes.0 = value
        return paramStruct
    }

    static func output() -> SMCParamStruct {
        return SMCParamStruct()
    }
}
