//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

@main
private enum BTService {
    private static func main() {
        BTServiceXPCServer.start()
    }
}
