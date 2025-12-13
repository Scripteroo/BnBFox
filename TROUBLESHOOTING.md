# BnBFox Troubleshooting Guide

## Project File Fix History

### Issue Encountered
The Xcode project file (project.pbxproj) was initially missing three critical files:
- AppSettings.swift
- NotificationService.swift  
- SettingsView.swift

### Root Cause
These files existed in the filesystem but were never added to the Xcode project target, causing "Cannot find in scope" build errors.

### Solution Applied
Used unique IDs (A100006x series) to add the files to avoid conflicts with existing build configuration IDs (A100005x series).

### File ID Mapping
- **AppSettings.swift**: File ID `A1000060000000000000001`, Build ID `A1000061000000000000001`
- **NotificationService.swift**: File ID `A1000062000000000000001`, Build ID `A1000063000000000000001`
- **SettingsView.swift**: File ID `A1000064000000000000001`, Build ID `A1000065000000000000001`

## Manual Setup Required

### Sea Turtle Animation
The `sea-turtle-swimming.mov` file must be added manually:

1. In Xcode, right-click the BnBFox folder in the Project Navigator
2. Select "Add Files to BnBFox..."
3. Navigate to and select `sea-turtle-swimming.mov`
4. Check "Copy items if needed"
5. Ensure "BnBFox" target is selected
6. Click "Add"

## Build Verification

After opening the project:
1. Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
2. Build the project: Product → Build (Cmd+B)
3. Verify no errors appear

## Common Issues

### "Cannot find X in scope" errors
If you still see these errors, verify the file is in the target:
1. Select the file in Project Navigator
2. Open File Inspector (right panel)
3. Under "Target Membership", ensure "BnBFox" is checked

### Missing sea turtle video
The app will work without it, but the loading animation won't appear. Follow the manual setup steps above.

### Project won't open
If Xcode says the project is damaged:
1. Extract the archive to a fresh location
2. Delete any existing "BnBFox 2" or similar folders
3. Open the .xcodeproj file directly

## Version Information
- **Current Version**: 4.0
- **Last Working Commit**: 8147531
- **Project File Format**: Xcode 14.0 compatible
