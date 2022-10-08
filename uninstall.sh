#!/bin/sh

##
# Uninstalls Battery Toolkit and its settings.
#
# Copyright (C) 2022 Marvin Häuser. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
##

# Remove the Battery Toolkit daemon.
sudo rm /Library/LaunchDaemons/EMH49F8A2Y.me.mhaeuser.batterytoolkitd.plist
sudo rm /Library/PrivilegedHelperTools/EMH49F8A2Y.me.mhaeuser.batterytoolkitd
sudo launchctl remove EMH49F8A2Y.me.mhaeuser.batterytoolkitd

# Remove the Battery Toolkit daemon data.
sudo defaults delete EMH49F8A2Y.me.mhaeuser.batterytoolkitd
sudo security authorizationdb remove EMH49F8A2Y.me.mhaeuser.batterytoolkitd.manage

# Remove the Battery Toolkit Autostart helper.
launchctl remove me.mhaeuser.BatteryToolkitAutostart

# Remove the Battery Toolkit app data.
defaults remove me.mhaeuser.BatteryToolkit
