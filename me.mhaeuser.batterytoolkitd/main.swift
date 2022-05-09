import Foundation

let powerResult = BTPowerEvents.start()
if powerResult {
    let xpcResult = BTHelperXPCServer.start()
    if !xpcResult {
        NSLog("XPC server start failed")
    }

    atexit {
        BTPowerEvents.stop()
    }

    CFRunLoopRun()
}

NSLog("Power events start failed")

exit(-1)
