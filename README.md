<p align="center">
 <img alt="Battery Toolkit logo" src="/Resources/LogoCaption.png" width=400 align="center">
</p>

<p align="center">Control the platform power state of your Apple Silicon Mac.</p>

<p align="center"><a href="#features">Features</a> &bull; <a href="#install">Install</a> &bull; <a href="#usage">Usage</a> &bull; <a href="#uninstall"> Uninstall </a> &bull; <a href="#compatibility"> Compatibility </a> &bull; <a href="#known-issues--caveats"> Known Issues / Caveats </a> &bull; <a href="#technical-details"> Technical Details </a></p>

-----

# Features

## Limits battery charge to an upper limit

Modern batteries deteriorate more when always kept at full charge. For this reason, Apple introduced the “Optimized Charging“ feature for all their portable devices, including Macs. However, its limit cannot be changed, and you cannot force charging to be put on hold. Battery Toolkit allows specifying a hard limit past which battery charging will be turned off. For safety reasons, this limit cannot be lower than 50 %.

## Allows battery charge to drain to a lower limit

Even when connected to power, your Mac's battery may slowly lose battery charge for various reasons. Short battery charging bursts can further deteriorate batteries. For this reason, Battery Toolkit allows specifying a limit only below which battery charging will be turned on. For safety reasons, this limit cannot be lower than 20 %.

**Note:** This setting is not honoured for cold boots or reboots, because Apple Silicon Macs reset their platform state in these cases. As battery charging will already be ongoing when Battery Toolkit starts, it lets charging proceed to the upper limit to not cause further short bursts across reboots.

## Allows you to disable the power adapter

If you want to discharge the battery of your Mac, e.g., to recalibrate it, you can turn off the power adapter without actually unplugging it. You can also have Battery Toolkit disable sleeping when the power adapter is disabled.

**Note:** Your Mac may go to sleep immediately after enabling the power adapter again. This is a software bug in macOS and cannot easily be worked around.

|![Power Settings](Resources/PowerSettings.png)|
|:--:| 
| *Battery Toolkit Power Settings* |

# Grants you manual control

The Battery Toolkit “Commands“ menu and its menu bar extra allow you to issue various commands related to the power state of your Mac. These include:
* Enabling and disabling the power adapter
* Requesting a full charge
* Requesting a charge to the specified upper limit
* Stopping charging immediately

|![Menu Bar Extra](Resources/MenuBarExtra.png)|
|:--:| 
| *Battery Toolkit Menu Bar Extra* |

# Install

### Manual Install
1. Go to the [releases](https://github.com/mhaeuser/Battery-Toolkit/releases/latest)
2. Download the newest non-dSYM build (e.g. `Battery-Toolkit-1.6.zip`)
3. Unzip it (double click)
4. Drag it into your Applications folder
5. Right click the `Battery Toolkit.app`, then click "Open", then allow in the dialog box
6. If that doesn't work, go to `System Settings -> Privacy & Security` and you should see a prompt at the bottom of the screen allow opening Battery Toolkit. Allow it.
7. Open Battery Toolkit again from Applications folder.

### Install via Homebrew
1. Install [Homebrew](https://brew.sh) if you haven't already.
2. Open Terminal and run `brew tap mhaeuser/mhaeuser`
2. Then run `brew install battery-toolkit --no-quarantine`
4. Type password if prompted.
5. Open Battery Toolkit from your Applications folder

> [!CAUTION]
> To ensure there is no chance of interference, please turn “Optimized Charging” **off** when Battery Toolkit is in use.

# Usage
1. Open Battery Toolkit
2. Click the menu bar icon
3. Configure your desired setting through the menu options

If you prefer, you can quit the GUI through the menu bar extra. Battery Toolkit will keep running in the background.
If you want to change any settings, simply re-open the app.

# Uninstall

1. Enable "Pause Background Activity" from the Battery Toolkit menu bar item
2. Move the app to the trash.

# Compatibility

* **Battery Toolkit currently only supports Apple Silicon Macs.**
* M4 series MacBooks may have some small issues [#55](https://github.com/mhaeuser/Battery-Toolkit/issues/55)

# Known Issues / Caveats

* Battery Toolkit disables sleep while it is charging, because it has to actively disable charging once reaching the maximum. [#83](https://github.com/mhaeuser/Battery-Toolkit/issues/83)
* Battery Toolkit cannot control the charge state when the machine is shut down. If charger remains plugged in while the Mac is off, battery will charge to 100% as normal.

# Technical Details

* Based on IOPowerManagement events to minimize resource usage, especially when not connected to power
* Support for macOS Ventura daemons and login items for a more reliable experience

## Security
* Privileged operations are authenticated by the daemon
* Privileged daemon exposes only a minimal protocol via XPC
* XPC communication uses the latest macOS codesign features

# Credits
* Icon based on [reference icon by Streamline](https://seekicon.com/free-icon/rechargable-battery_1)
