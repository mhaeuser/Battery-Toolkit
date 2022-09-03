import Foundation

func main() -> Never {
    let powerResult = BTPowerEvents.start()
    if !powerResult {
        NSLog("Power events start failed")
        exit(-1)
    }

    let xpcResult = BTHelperXPCServer.start()
    if !xpcResult {
        NSLog("XPC server start failed")
    }

    let termSource = DispatchSource.makeSignalSource(signal: SIGTERM)
    termSource.setEventHandler {
        BTPowerEvents.stop()
        exit(0)
    }
    termSource.resume()
    //
    // Ignore SIGTERM to catch it above and gracefully stop the service.
    //
    signal(SIGTERM, SIG_IGN)

    dispatchMain()
}

main()
