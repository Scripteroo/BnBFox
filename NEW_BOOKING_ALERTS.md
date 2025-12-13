# New Booking Alerts Feature

## Overview
Automatically notifies users when new bookings appear in the current month for any property.

## How It Works

### Detection Logic
1. **Tracks booking IDs** - Stores a set of all known booking IDs
2. **Compares on refresh** - When calendar refreshes, compares current bookings with previous
3. **Identifies new bookings** - Any booking ID not in previous set is considered "new"
4. **Current month filter** - Only alerts for bookings starting in the current month
5. **Property-specific** - Shows which property the booking is for

### Notification Format
**Title:** 📅 New Booking  
**Body:** New booking in [Property Name]  
**Subtitle:** [Start Date] - [End Date]  
**Sound:** Respects user's alert sound setting

### Examples
- "New booking in Kawama C-2" (Dec 15, 2025 - Dec 20, 2025)
- "New booking in Kawama E-5" (Dec 1, 2025 - Dec 5, 2025)
- "New booking in Kawama C-5" (Dec 25, 2025 - Dec 31, 2025)

## Settings

### Toggle Control
Users can enable/disable new booking alerts independently from cleaning alerts:
- **Location:** Settings → New Booking Alerts
- **Default:** ON
- **Info text:** "Get notified when new bookings appear in the current month"

### Sound Control
New booking alerts respect the global "Alert Sound" setting in Cleaning Day Alerts section.

## Technical Implementation

### Files Modified
1. **AppSettings.swift** - Added `newBookingAlertsEnabled` property
2. **NotificationService.swift** - Added booking tracking and notification logic
3. **CalendarViewModel.swift** - Integrated new booking detection on refresh
4. **SettingsView.swift** - Added UI toggle for new booking alerts

### Key Methods
- `checkForNewBookings(_ currentBookings: [Booking])` - Detects and notifies
- `initializeBookingTracking(_ bookings: [Booking])` - Sets initial state
- `sendNewBookingNotification(propertyName:booking:)` - Sends notification

### Trigger Points
- **App launch** - Initializes tracking (no notifications)
- **Manual refresh** - Checks for new bookings
- **Auto refresh** - Checks for new bookings (every 15 minutes via cache expiry)

## User Experience

### First Launch
- No notifications sent
- All current bookings are stored as "known"

### Subsequent Refreshes
- If new booking appears in current month → Immediate notification
- If new booking is in past/future months → No notification
- Multiple new bookings → One notification per booking

### Notification Timing
- Fires **immediately** (1 second delay for iOS processing)
- No scheduling needed (unlike cleaning alerts)
- Instant feedback when new bookings detected

## Testing

### How to Test
1. **Enable feature** in Settings
2. **Note current bookings** in the current month
3. **Add a new booking** to one of the iCal feeds
4. **Pull to refresh** the calendar
5. **Expect notification** "New booking in [Property Name]"

### Edge Cases Handled
- ✅ First app launch (no false positives)
- ✅ Bookings outside current month (ignored)
- ✅ Duplicate bookings (same ID = not new)
- ✅ Multiple properties (shows correct property name)
- ✅ Feature disabled (no notifications)

## Future Enhancements
- Add notification for booking cancellations
- Show booking details in notification tap
- Group multiple new bookings into one notification
- Add filter for specific properties only
