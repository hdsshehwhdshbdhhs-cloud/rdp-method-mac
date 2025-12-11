#!/bin/bash

# setup.sh

# 1. Handle Arguments
# $1 = System User Password
# $2 = VNC Password
# $3 = Ngrok Token

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: Missing arguments. Usage: ./setup.sh <UserPass> <VNCPass> <NgrokToken>"
    exit 1
fi

echo "--- Disabling Spotlight Indexing ---"
sudo mdutil -i off -a

echo "--- Creating User Account 'alone' ---"
sudo dscl . -create /Users/alone
sudo dscl . -create /Users/alone UserShell /bin/bash
sudo dscl . -create /Users/alone RealName "Alone"
sudo dscl . -create /Users/alone UniqueID 1001
sudo dscl . -create /Users/alone PrimaryGroupID 80
sudo dscl . -create /Users/alone NFSHomeDirectory /Users/alone
sudo dscl . -passwd /Users/alone "$1"
sudo createhomedir -c -u alone > /dev/null

echo "--- Configuring VNC ---"
# Enable VNC and allow legacy connections
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes 

# Set VNC Password
echo "$2" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Restart ARD Agent to apply changes
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

echo "--- Installing and Configuring Ngrok ---"
brew install --cask ngrok

# Authenticate Ngrok
ngrok authtoken "$3"

# Start Ngrok in the background (India region)
ngrok tcp 5900 --region=in > /dev/null 2>&1 &

echo "--- Waiting for Ngrok to initialize... ---"
sleep 10
