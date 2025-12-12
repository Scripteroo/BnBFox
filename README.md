# BnBFox - Rental Calendar App

An iOS app for managing Bed & Breakfast property bookings by displaying calendars from AirBnB and VRBO in real-time.

## Overview

BnBFox helps cleaning crews and property managers view rental unit booking calendars by automatically fetching and displaying iCal data from multiple booking platforms. The app provides a clean, calendar-based interface showing check-in and check-out dates for all properties.

## Features

- **Multi-Platform Support**: Integrates with AirBnB and VRBO (Booking.com ready for future)
- **Real-Time Updates**: Fetch latest booking data with pull-to-refresh
- **All Properties View**: See all rental units on one calendar
- **Visual Calendar**: Month-by-month grid view with horizontal booking bars
- **Property-Based Colors**: Orange for C-2, Yellow for E-5
- **Check-In/Check-Out Visualization**: Bars show 4PM check-in and 10AM checkout times
- **Cross-Month Visibility**: Grayed-out bars show bookings extending into adjacent months
- **Clickable Dates**: Tap dates with activity to see detailed check-in/check-out information
- **Activity Indicators**: Orange dots mark dates with turnover activity
- **Guest Names**: Displays guest names when available

## Current Properties

- **Kawama C-2**: Integrated with VRBO and AirBnB
- **Kawama E-5**: Integrated with VRBO and AirBnB

## Requirements

- **Xcode**: 15.0 or later
- **iOS**: 16.0 or later
- **Device**: iPhone only (iPad not supported)
- **macOS**: Ventura (13.0) or later for development

## Installation & Setup

### 1. Open the Project

1. Navigate to the project folder
2. Double-click `BnBFox.xcodeproj` to open in Xcode
3. Wait for Xcode to index the project

### 2. Configure Signing

1. Select the **BnBFox** project in the navigator
2. Select the **BnBFox** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** from the dropdown
5. Xcode will automatically manage provisioning profiles

### 3. Build and Run

**Using Simulator:**
1. Select an iPhone simulator from the device menu (e.g., "iPhone 15 Pro")
2. Press `Cmd + R` or click the Play button
3. The app will build and launch in the simulator

**Using Physical Device:**
1. Connect your iPhone via USB
2. Select your device from the device menu
3. Press `Cmd + R` to build and run
4. You may need to trust the developer certificate on your device:
   - Go to **Settings > General > VPN & Device Management**
   - Tap your developer profile and tap **Trust**

## Project Structure

```
BnBFox/
├── BnBFox.xcodeproj/          # Xcode project file
├── BnBFox/
│   ├── BnBFoxApp.swift        # App entry point
│   ├── Models/                # Data models
│   │   ├── Platform.swift     # Booking platform enum
│   │   ├── Property.swift     # Rental property model
│   │   ├── CalendarSource.swift
│   │   └── Booking.swift      # Booking event model
│   ├── Services/              # Business logic
│   │   ├── ICalService.swift  # iCal parsing
│   │   ├── BookingService.swift
│   │   └── PropertyService.swift
│   ├── ViewModels/            # View state management
│   │   └── CalendarViewModel.swift
│   ├── Views/                 # UI components
│   │   ├── CalendarView.swift
│   │   ├── MonthView.swift
│   │   ├── DayCell.swift
│   │   ├── BookingBadge.swift
│   │   └── PropertySelectorView.swift
│   ├── Utilities/             # Helper functions
│   │   └── DateExtensions.swift
│   └── Assets.xcassets/       # Images and colors
└── README.md
```

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models**: Define data structures for properties, bookings, and calendar sources
- **Services**: Handle data fetching and parsing from iCal feeds
- **ViewModels**: Manage state and coordinate between services and views
- **Views**: SwiftUI components for the user interface

## How It Works

### Data Flow

1. **App Launch**: PropertyService loads predefined properties with their iCal URLs
2. **Data Fetch**: BookingService fetches iCal data from all sources concurrently
3. **Parsing**: ICalService parses iCal format into Booking objects
4. **Display**: CalendarViewModel updates the UI with parsed bookings
5. **Refresh**: User can pull to refresh or tap the refresh button for latest data

### iCal Integration

The app fetches iCal (.ics) feeds from:
- VRBO: Provides guest names in the format "Reserved - Name"
- AirBnB: Shows "Reserved" without guest names

Each booking includes:
- Start date (check-in)
- End date (check-out)
- Guest name (VRBO only)
- Platform identifier
- Unique booking ID

## Adding New Properties

To add a new rental unit:

1. Open `BnBFox/Services/PropertyService.swift`
2. Add a new `Property` object to the `properties` array:

```swift
Property(
    name: "property-id",
    displayName: "Display Name",
    sources: [
        CalendarSource(
            platform: .vrbo,
            url: URL(string: "VRBO_ICAL_URL")!
        ),
        CalendarSource(
            platform: .airbnb,
            url: URL(string: "AIRBNB_ICAL_URL")!
        )
    ]
)
```

3. Build and run the app

## Customization

### Changing Colors

Platform colors are defined in `Models/Platform.swift`:

```swift
var color: Color {
    switch self {
    case .airbnb:
        return Color(red: 1.0, green: 0.36, blue: 0.45)
    case .vrbo:
        return Color(red: 0.0, green: 0.42, blue: 0.76)
    case .bookingCom:
        return Color(red: 0.0, green: 0.27, blue: 0.64)
    }
}
```

### Adjusting Calendar Display

- **Months to show**: Edit `getMonthsToDisplay(count:)` in `CalendarViewModel.swift`
- **Bookings per cell**: Change `maxVisibleBookings` in `DayCell.swift`
- **Cell height**: Modify `.frame(height:)` in `DayCell.swift`

## Git Integration

The project is initialized with Git and ready for version control:

```bash
# View status
git status

# Create a new commit (from Xcode or terminal)
git add .
git commit -m "Your commit message"

# Add remote repository
git remote add origin YOUR_REPO_URL
git push -u origin main
```

### Committing from Xcode

1. Go to **Source Control > Commit** (or press `Cmd + Option + C`)
2. Review changes in the commit window
3. Enter a commit message
4. Click **Commit** to save changes locally
5. Use **Source Control > Push** to sync with remote repository

## Troubleshooting

### Build Errors

**"No such module 'SwiftUI'"**
- Ensure you're targeting iOS 16.0 or later
- Check that the deployment target is set correctly in project settings

**Signing errors**
- Select a valid development team in Signing & Capabilities
- Ensure your Apple ID is added to Xcode preferences

### Runtime Issues

**"Failed to load bookings"**
- Check internet connection
- Verify iCal URLs are still valid
- Check console logs for specific error messages

**Bookings not appearing**
- Ensure the iCal feeds contain valid VEVENT entries
- Check date formats in the iCal data
- Verify the property ID matches between services

**App crashes on launch**
- Clean build folder: **Product > Clean Build Folder** (`Cmd + Shift + K`)
- Delete derived data: **Xcode > Preferences > Locations > Derived Data**
- Restart Xcode and rebuild

## Testing

### Manual Testing Checklist

- [ ] App launches successfully
- [ ] Calendar displays current month
- [ ] Bookings appear on correct dates
- [ ] Platform colors are correct (AirBnB pink, VRBO blue)
- [ ] Property selector switches between units
- [ ] Refresh button fetches new data
- [ ] Scrolling through months works smoothly
- [ ] Today's date is highlighted
- [ ] Multi-day bookings span correctly across dates
- [ ] Guest names appear for VRBO bookings

### Testing with Simulator

1. Launch app in iPhone simulator
2. Verify calendar loads with bookings
3. Test property switching
4. Test refresh functionality
5. Scroll through multiple months
6. Check memory usage in Xcode's Debug Navigator

## Future Enhancements

Planned features for future versions:

- [ ] Booking.com integration
- [ ] Detailed booking view with guest information
- [ ] Push notifications for new bookings
- [ ] Cleaning schedule management
- [ ] Offline mode with cached data
- [ ] Settings screen for managing properties
- [ ] Export calendar to PDF
- [ ] Multi-user support with authentication

## Support

For issues or questions:
- Check the troubleshooting section above
- Review Xcode console logs for error messages
- Verify iCal URLs are accessible in a web browser

## License

This project is created for personal use in managing BnB properties.

## Version History

- **1.0.0** (December 2025)
  - Initial release
  - AirBnB and VRBO integration
  - Calendar view with booking display
  - Property switching
  - Pull-to-refresh functionality
