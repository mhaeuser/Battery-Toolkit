//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa

@MainActor
internal final class BTUpgradingViewController: NSViewController {
    @IBOutlet private var progress: NSProgressIndicator!

    override func viewWillAppear() {
        super.viewWillAppear()
        self.progress.startAnimation(self)
    }
}
