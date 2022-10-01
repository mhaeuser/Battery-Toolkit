#!/bin/sh

##
# Copyright (C) 2022 Marvin Häuser. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
##

# Remove the Battery Toolkit daemon.
sudo rm /Library/LaunchDaemons/me.mhaeuser.batterytoolkitd.plist
sudo rm /Library/PrivilegedHelperTools/me.mhaeuser.batterytoolkitd
sudo launchctl remove me.mhaeuser.batterytoolkitd

# Remove the Battery Toolkit daemon data.
sudo defaults delete me.mhaeuser.batterytoolkitd
sudo security authorizationdb remove me.mhaeuser.batterytoolkitd.manage

# Remove the Battery Toolkit Autostart helper.
launchctl remove me.mhaeuser.BatteryToolkitAutostart

# Remove the Battery Toolkit app data.
defaults remove me.mhaeuser.BatteryToolkit
