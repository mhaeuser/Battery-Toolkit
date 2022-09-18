/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

@MainActor
private func main() -> Never {
    let powerResult = BTPowerEvents.start()
    guard powerResult else {
        os_log("Power events start failed")
        exit(-1)
    }

    BTDaemonXPCServer.start()

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
