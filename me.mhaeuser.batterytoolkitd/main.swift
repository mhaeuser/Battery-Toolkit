/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

private func main() -> Never {
    let powerResult = BTPowerEvents.start()
    if !powerResult {
        os_log("Power events start failed")
        exit(-1)
    }

    let xpcResult = BTHelperXPCServer.start()
    if !xpcResult {
        os_log("XPC server start failed")
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
