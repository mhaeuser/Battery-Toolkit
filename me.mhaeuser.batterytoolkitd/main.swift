/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

@MainActor
private func main() -> Never {
    let prepareResult = BTPowerEvents.prepare()
    guard prepareResult else {
        os_log("Power events preparation failed")
        exit(-1)
    }

    let supported = BTPowerEvents.supported()
    guard supported else {
        os_log("Machine is unsupported")
        exit(0)
    }

    let startResult = BTPowerEvents.start()
    guard startResult else {
        os_log("Power events start failed")
        exit(-1)
    }

    let termSource = DispatchSource.makeSignalSource(signal: SIGTERM)
    termSource.setEventHandler {
        BTPowerEvents.exit()
        exit(0)
    }
    termSource.resume()
    //
    // Ignore SIGTERM to catch it above and gracefully stop the service.
    //
    signal(SIGTERM, SIG_IGN)

    BTDaemonXPCServer.start()

    dispatchMain()
}

main()
