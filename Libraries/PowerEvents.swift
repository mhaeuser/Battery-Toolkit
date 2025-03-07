//
// Copyright (C) 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import IOKit.pwr_mgt

@MainActor
public enum PowerEvents {
    private static func err_system(_ x: UInt32) -> UInt32 { return (x & 0x3f) << 26 }
    private static func err_sub(_ x: UInt32) -> UInt32 { return (x & 0xfff) << 14 }
    private static let sys_iokit = err_system(0x38)
    private static let sub_iokit_common = err_sub(0)
    private static func iokit_common_msg(_ message: UInt32) -> UInt32 {
        return (sys_iokit|sub_iokit_common|message)
    }
    
    static let kIOMessageCanSystemSleep = iokit_common_msg(0x270)
    static let kIOMessageSystemWillSleep = iokit_common_msg(0x280)
    static let kIOMessageSystemHasPoweredOn = iokit_common_msg(0x300)
    
    private static var notifyPortRef: IONotificationPortRef? = nil
    private static var notifierObject: io_object_t = IO_OBJECT_NULL
    private(set) static var root_port: io_connect_t = IO_OBJECT_NULL
    
    static func register(callback: IOServiceInterestCallback) -> Bool {
        assert(self.root_port == IO_OBJECT_NULL)
        assert(self.notifyPortRef == nil)
        assert(self.notifierObject == IO_OBJECT_NULL)

        self.root_port = IORegisterForSystemPower(
            nil,
            &self.notifyPortRef,
            callback,
            &self.notifierObject
        )
        guard self.root_port != IO_OBJECT_NULL else {
            return false
        }

        assert(self.notifyPortRef != nil)
        assert(self.notifierObject != IO_OBJECT_NULL)

        IONotificationPortSetDispatchQueue(
            self.notifyPortRef!,
            DispatchQueue.main
        )
        
        return true
    }

    static func deregister() {
        assert(self.root_port != IO_OBJECT_NULL)
        assert(self.notifyPortRef != nil)
        assert(self.notifierObject != IO_OBJECT_NULL)

        IODeregisterForSystemPower(&self.notifierObject)
        IOServiceClose(self.root_port)
        IONotificationPortDestroy(self.notifyPortRef!)

        self.root_port = IO_OBJECT_NULL
        self.notifyPortRef = nil
        self.notifierObject = IO_OBJECT_NULL
    }
}
