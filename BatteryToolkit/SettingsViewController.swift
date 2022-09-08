import Cocoa

final class SettingsViewController: NSViewController {
    @IBOutlet weak var minChargeTextField: NSTextField!
    @IBOutlet weak var minChargeSlider: NSSlider!
    
    @IBOutlet weak var maxChargeTextField: NSTextField!
    @IBOutlet weak var maxChargeSlider: NSSlider!
    
    @IBOutlet weak var adapterSleepButton: NSButton!

    private var minChargeVal = BTSettingsInfo.minChargeDefault
    @objc dynamic var minChargeNum: NSNumber {
        get {
            return NSNumber(value: self.minChargeVal)
        }
        
        set {
            let value = newValue.intValue
            //
            // For clamping, the assignment needs to be async, because otherwise
            // the source control does not get notified of the update. We cannot
            // change the values of the UI controls directly, because this
            // caues the NSSlider to sometimes visually desync with its value.
            //
            if value < BTSettingsInfo.minChargeMin {
                DispatchQueue.main.async {
                    self.minChargeNum = NSNumber(
                        value: BTSettingsInfo.minChargeMin
                        )
                }
                
            } else if value > 100 {
                DispatchQueue.main.async {
                    self.minChargeNum = NSNumber(value: 100)
                }
            } else {
                self.minChargeVal = UInt8(value)
                //
                // Clamp the maximum charge to be at least the minimum charge.
                //
                if self.maxChargeVal < self.minChargeVal {
                    self.maxChargeNum = self.minChargeNum
                }
            }
        }
    }
    
    private var maxChargeVal = BTSettingsInfo.maxChargeDefault
    @objc dynamic var maxChargeNum: NSNumber {
        get {
            return NSNumber(value: self.maxChargeVal)
        }
        
        set {
            let value = newValue.intValue
            //
            // See minChargeNum for an explanation.
            //
            if value < BTSettingsInfo.maxChargeMin {
                DispatchQueue.main.async {
                    self.maxChargeNum = NSNumber(
                        value: BTSettingsInfo.maxChargeMin
                        )
                }
            } else if value > 100 {
                DispatchQueue.main.async {
                    self.maxChargeNum = NSNumber(value: 100)
                }
            } else {
                self.maxChargeVal = UInt8(value)
                //
                // Clamp the maximum charge to be at least the minimum charge.
                //
                if self.maxChargeVal < self.minChargeVal {
                    self.minChargeNum = self.maxChargeNum
                }
            }
        }
    }
    
    private func initAdapterSleepState() {
        self.adapterSleepButton.state = BTSettingsInfo.adapterSleep ?
            NSControl.StateValue.off :
            NSControl.StateValue.on
    }
    
    @IBAction func restoreDefaultsButtonAction(_ sender: NSButton) {
        self.minChargeNum = NSNumber(value: BTSettingsInfo.minChargeDefault)
        self.maxChargeNum = NSNumber(value: BTSettingsInfo.maxChargeDefault)
        self.initAdapterSleepState()
    }
    
    @IBAction func cancelButtonAction(_ sender: NSButton) {
        self.view.window?.windowController?.close()
    }
    
    @IBAction func okButtonAction(_ sender: NSButton) {
        BTHelperXPCClient.setChargeLimits(
            minCharge: self.minChargeVal,
            maxCharge: self.maxChargeVal
            )
        BTHelperXPCClient.setAdapterSleep(
            enabled: self.adapterSleepButton.state == NSControl.StateValue.off
            )
        self.view.window?.windowController?.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initAdapterSleepState()
    }
}
