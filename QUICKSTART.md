# BnBFox Quick Start Guide

Get your rental calendar app running in 5 minutes!

## Prerequisites

- Mac with macOS Ventura (13.0) or later
- Xcode 15.0 or later installed
- Apple Developer account (free or paid)

## Step 1: Open the Project

1. Download and extract the BnBFox project folder
2. Navigate to the folder and double-click **BnBFox.xcodeproj**
3. Xcode will open the project automatically

## Step 2: Configure Code Signing

1. In Xcode, select **BnBFox** in the project navigator (left sidebar)
2. Select the **BnBFox** target in the main editor
3. Click the **Signing & Capabilities** tab
4. Under **Signing**, select your **Team** from the dropdown
   - If you don't see your team, add your Apple ID in **Xcode > Settings > Accounts**
5. Xcode will automatically generate a provisioning profile

## Step 3: Choose Your Device

### Option A: Run on Simulator (Recommended for Testing)

1. Click the device selector at the top of Xcode (next to the play/stop buttons)
2. Select any iPhone simulator (e.g., **iPhone 15 Pro**)
3. Press **⌘ + R** (or click the Play ▶️ button)
4. Wait for the simulator to launch and the app to install

### Option B: Run on Your iPhone

1. Connect your iPhone to your Mac with a USB cable
2. Unlock your iPhone and trust the computer if prompted
3. In Xcode, select your iPhone from the device selector
4. Press **⌘ + R** to build and run
5. If you see a "Developer Not Trusted" error on your iPhone:
   - Open **Settings > General > VPN & Device Management**
   - Tap your developer profile
   - Tap **Trust** and confirm

## Step 4: Use the App

Once the app launches:

1. **Wait for data to load**: The app will fetch bookings from AirBnB and VRBO
2. **View bookings**: Scroll through the calendar to see all bookings
3. **Switch properties**: Tap the property name dropdown to switch between Kawama C-2 and E-5
4. **Refresh data**: Tap the refresh icon (↻) to fetch the latest bookings
5. **Scroll months**: Swipe up/down to view different months

## Understanding the Calendar

- **Blue circle**: Today's date
- **Colored badges**: Bookings (pink = AirBnB, blue = VRBO)
- **Guest names**: Shown on VRBO bookings (first day of stay)
- **Multi-day bookings**: Span across multiple dates

## Troubleshooting

### "Failed to load bookings"

- Check that your Mac has internet connection
- The iCal URLs may be temporarily unavailable
- Tap the refresh button to retry

### Build fails in Xcode

- Make sure you selected a Team in Signing & Capabilities
- Try **Product > Clean Build Folder** (⌘ + Shift + K)
- Restart Xcode and try again

### App doesn't appear on iPhone

- Check that your iPhone is unlocked
- Verify the device is selected in Xcode's device menu
- Try disconnecting and reconnecting the USB cable

## Next Steps

- Read **README.md** for full documentation
- Check **DEVELOPMENT.md** for technical details
- Customize the app by editing property information in `PropertyService.swift`

## Need Help?

Common solutions:
- **Clean build**: Product > Clean Build Folder (⌘ + Shift + K)
- **Reset simulator**: Device > Erase All Content and Settings
- **Update Xcode**: Check App Store for updates
- **Check console**: View > Debug Area > Show Debug Area (⌘ + Shift + Y)

## Adding Your Own Properties

To add your own rental units:

1. Get the iCal URLs from AirBnB and VRBO:
   - **AirBnB**: Calendar > Availability Settings > Export Calendar
   - **VRBO**: Calendar > Export Calendar > Copy iCal Link
2. Open `BnBFox/Services/PropertyService.swift` in Xcode
3. Add a new property to the `properties` array:

```swift
Property(
    name: "your-property-id",
    displayName: "Your Property Name",
    sources: [
        CalendarSource(
            platform: .vrbo,
            url: URL(string: "YOUR_VRBO_ICAL_URL")!
        ),
        CalendarSource(
            platform: .airbnb,
            url: URL(string: "YOUR_AIRBNB_ICAL_URL")!
        )
    ]
)
```

4. Build and run the app (⌘ + R)
5. Your new property will appear in the property selector

That's it! You're ready to use BnBFox to manage your rental calendars.
