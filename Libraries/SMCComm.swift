//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import IOKit
import os

import MachTaskSelf
import SMCParamStruct

private func UInt32FromBytes(
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

private func BytesFromUInt32(_ value: UInt32) -> (UInt8, UInt8, UInt8, UInt8) {
    return (
        UInt8((value & 0xFF000000) >> 24),
        UInt8((value & 0x00FF0000) >> 16),
        UInt8((value & 0x0000FF00) >> 8),
        UInt8(value & 0x000000FF)
    )
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
        self = UInt32FromBytes(
            char0.asciiValue!,
            char1.asciiValue!,
            char2.asciiValue!,
            char3.asciiValue!
        )
    }
}

public extension SMCComm {
    typealias Key = SMCId
    typealias KeyType = SMCId

    typealias KeyInfoData = SMCKeyInfoData

    struct KeyInfo : Sendable {
        let key: SMCComm.Key
        let info: SMCComm.KeyInfoData
    }

    enum KeyTypes {
        static let ui8  = SMCComm.KeyType("u", "i", "8", " ")
        static let ui32 = SMCComm.KeyType("u", "i", "3", "2")
        static let hex  = SMCComm.KeyType("h", "e", "x", "_")
    }
    
    static func KeyInfoDataEq (
        data1: SMCComm.KeyInfoData,
        data2: SMCComm.KeyInfoData
    ) -> Bool {
        return data1.dataSize == data2.dataSize &&
            data1.dataType == data2.dataType &&
            data1.dataAttributes == data2.dataAttributes
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

        var connect: io_connect_t = IO_OBJECT_NULL
        let resultOpen = IOServiceOpen(
            smc,
            get_mach_task_self(),
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

    static func keySupported(keyInfo: SMCComm.KeyInfo) -> Bool {
        let info = SMCComm.getKeyInfo(key: keyInfo.key)
        guard let info = info,
              SMCComm.KeyInfoDataEq(data1: keyInfo.info, data2: info) else {
            return false
        }
        
        return true
    }

    static func readKey(key: SMCComm.Key, dataSize: Int) -> [UInt8]? {
        var inputStruct = SMCParamStruct.readKey(key: key, dataSize: UInt32(dataSize))

        let outputStruct = self.callSMCFunctionYPC(params: &inputStruct)
        guard let outputStruct else {
            return nil
        }
        
        let mirror = Mirror(reflecting: outputStruct.bytes)
        let data = mirror.children.prefix(dataSize)
        return data.map { byte in byte.value as! UInt8 }
    }

    static func writeKey(key: SMCComm.Key, bytes: [UInt8]) -> Bool {
        var inputStruct = SMCParamStruct.writeKey(key: key, bytes: bytes)

        let outputStruct = self.callSMCFunctionYPC(params: &inputStruct)
        //
        // This is defensive programming to protect against the SMC driver
        // misreporting success or failure. No such occasions were identified so
        // far. What has been identified so far were SMC keys reporting values
        // different from both the previous value and what has been written.
        //
        let readValue = self.readKey(key: key, dataSize: bytes.count)
        guard let readValue else {
            //
            // If the read fails, return the write result.
            //
            return outputStruct != nil
        }
        //
        // If the read succeeds, compare the current to the written value.
        //
        return readValue == bytes
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

    static func readKey(key: SMCComm.Key, dataSize: UInt32) -> SMCParamStruct {
        var paramStruct = SMCParamStruct()
        paramStruct.key = key
        paramStruct.keyInfo.dataSize = dataSize
        paramStruct.data8 = UInt8(kSMCReadKey)
        return paramStruct
    }

    static func writeKey(key: SMCComm.Key, bytes: [UInt8]) -> SMCParamStruct {
        var paramStruct = SMCParamStruct()
        precondition(bytes.count < Mirror(reflecting: paramStruct.bytes).children.count);
        paramStruct.key = key
        paramStruct.keyInfo.dataSize = UInt32(bytes.count)
        paramStruct.data8 = UInt8(kSMCWriteKey)
        _ = withUnsafeMutablePointer(to: &paramStruct.bytes) { pointer in
            memcpy(pointer, bytes, bytes.count)
        }
        return paramStruct
    }

    static func output() -> SMCParamStruct {
        return SMCParamStruct()
    }
}
