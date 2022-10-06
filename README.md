![](Resources/LogoCaption.png)

-----

Allows you to control the platform power state of your Apple Silicon Mac.

# Features

## Limits battery charge to an upper threshold

Modern batteries deteriorate more when always kept at full charge. For this reason, Apple introduced the “Optimized Charging“ feature for all their portable devices, including Macs. However, its threshold cannot be changed, and you cannot force charging to be put on hold. Battery Toolkit allows to specify a hard threshold past which battery charging will be turned off. For safety reasons, this threshold cannot be lower than 50 %.

**Note:** To ensure there is no chance of interference, please turn “Optimized Charging” **off** when Battery Toolkit is in use.

## Allows battery charge to drain to a lower threshold

Even when connected to power, your Mac's battery may slowly lose battery charge for various reasons. Short battery charging bursts can further deteriorate batteries. For this reason, Battery Toolkit allows to specify a threshold only below which battery charging will be turned on. For safety reasons, this threshold cannot be lower than 20 %.

**Note:** This setting is not honoured for cold boots or reboots, because Apple Silicon Macs reset their platform state in these cases. As battery charging will already be ongoing when Battery Toolkit starts, it lets charging proceed to the upper threshold to not cause further short bursts across reboots.

## Allows you to disable the power adapter

If you want to discharge the battery of your Mac, e.g., to recalibrate it, you can turn off the power adapter without actually unplugging it. You can also have Battery Toolkit disable sleeping when the power adapter is disabled.

**Note:** Your Mac may go to sleep immediately after enabling the power adapter again. This is a software bug in macOS and cannot easily be worked around.

|![Power Settings](Resources/PowerSettings.png)|
|:--:| 
| *Battery Toolkit Power Settings* |

# Grants you manual control

The Battery Toolkit “Commands“ menu and its menus bar extra allow you to issue various commands related to the power state of your Mac. These include:
* Enabling and disabling the power adapter
* Requesting a full charge
* Requesting a charge to the specified upper threshold
* Stopping charging immediately

|![Menu Bar Extra](Resources/MenuBarExtra.png)|
|:--:| 
| *Battery Toolkit Menu Bar Extra* |

# Compatibility

Battery Toolkit currently supports only Apple Silicon Macs.

# Technical details

* Based on IOPowerManagement events to minimize resource usage, especially when not connected to power
* Support for macOS Ventura daemons and login items for a more reliable experience

## Security
* The main application, outside calls to the Authorization Services, is fully sandboxed
* Privileged operations are authenticated by the daemon
* Privileged daemon exposes only a minimal protocol via XPC
* XPC communication uses the latest macOS codesign features