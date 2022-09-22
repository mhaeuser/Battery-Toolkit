/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa

final class UpgradingViewController: NSViewController {
    @IBOutlet weak var progress: NSProgressIndicator!

    override func viewWillAppear() {
        super.viewWillAppear()
        self.progress.startAnimation(nil)
    }
}
