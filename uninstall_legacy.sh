#!/bin/sh

sudo rm /Library/LaunchDaemons/me.mhaeuser.batterytoolkitd.plist
sudo rm /Library/LaunchDaemons/me.mhaeuser.batterytoolkitlegacyd.plist
sudo rm /Library/PrivilegedHelperTools/me.mhaeuser.batterytoolkitd
sudo rm /Library/PrivilegedHelperTools/me.mhaeuser.batterytoolkitlegacyd
sudo launchctl remove me.mhaeuser.batterytoolkitd
sudo launchctl remove me.mhaeuser.batterytoolkitlegacyd
