# Admin Panel Documentation

## Overview

The Kawama Calendar app now includes an **Administration Panel** that allows cleaners to manage rental properties and their iCal feed URLs.

## Accessing the Admin Panel

1. Tap the **gear icon** (⚙️) in the top right corner of the calendar view
2. The "Kawama Maintenance Administration Panel" will open

## Features

### Managing Properties

#### Current Properties
- **Kawama C-2** (Orange)
  - AirBnB iCal URL: Pre-populated
  - VRBO iCal URL: Pre-populated
  - Booking.com iCal URL: Available

- **Kawama E-5** (Yellow)
  - AirBnB iCal URL: Pre-populated
  - VRBO iCal URL: Pre-populated
  - Booking.com iCal URL: Available

#### Adding New Properties

1. Scroll to the bottom of the admin panel
2. Tap the **blue plus button** (➕)
3. A new property card will appear with the name "Unit#X"
4. Enter the iCal URLs for each platform:
   - AirBnB iCal
   - VRBO iCal
   - Booking.com iCal
5. Tap "Done" to save

**Notes:**
- You can add up to **6 properties** total
- Each new property is automatically assigned a unique color
- Colors cycle through: Orange, Yellow, Green, Blue, Purple, Pink

#### Editing Properties

**Lock/Unlock Feature:**
- All properties are **locked by default** to prevent accidental changes
- Tap the **lock icon** (🔒) to unlock a property for editing
- When locked: Green lock icon, all fields are read-only
- When unlocked: Gray open lock icon, all fields are editable

**Editing Steps:**
1. Tap the **green lock icon** to unlock the property
2. Edit any of the following:
   - Complex name (e.g., "Kawama")
   - Unit name (e.g., "C-2")
   - AirBnB iCal URL
   - VRBO iCal URL
   - Booking.com iCal URL
3. Tap the **lock icon** again to lock and protect your changes
4. Tap "Done" to save all changes

#### Deleting Properties

1. Find the property you want to remove
2. Tap the **lock icon** to unlock the property
3. The **red X button** (⊗) will appear next to the lock icon
4. Tap the red X button to delete
5. The property will be removed immediately
6. Tap "Done" to save changes

**Notes:**
- Properties must be **unlocked** before they can be deleted
- The delete button only appears when a property is unlocked
- This prevents accidental deletion

### iCal URL Format

iCal URLs should be in this format:
```
https://www.airbnb.com/calendar/ical/[ID].ics?s=[SECRET]
https://www.vrbo.com/icalendar/[ID].ics?nonTentative
https://www.booking.com/calendar/[ID].ics
```

### Data Persistence

- All property configurations are saved to device storage (UserDefaults)
- Changes persist across app restarts
- When you add or modify properties, the calendar automatically refreshes

### Calendar Display

- Each property is shown with its assigned color in the calendar
- Booking bars display in the property's color
- The legend at the top shows all active properties with their colors
- Properties are displayed in the order they appear in the admin panel

## Workflow for Adding a New Unit (e.g., Kawama C-5)

1. Open the admin panel (gear icon)
2. Tap the plus button at the bottom
3. A new property "Unit#1" appears
4. Edit the property name if desired (currently shows as "Unit#1")
5. Paste the AirBnB iCal URL for C-5
6. Paste the VRBO iCal URL for C-5
7. (Optional) Paste the Booking.com iCal URL for C-5
8. Tap "Done"
9. The calendar will refresh and show C-5 bookings

## Technical Details

### Property Limits
- **Maximum properties**: 6
- **Minimum properties**: 1 (cannot delete all properties)

### Supported Platforms
- AirBnB
- VRBO
- Booking.com

### Color Assignment
Properties are assigned colors in this order:
1. Orange (C-2)
2. Yellow (E-5)
3. Green
4. Blue
5. Purple
6. Pink

### Calendar Scaling
- The calendar is designed to accommodate up to 6 properties
- Booking bars are thin (16px) to fit multiple properties per week
- If more visual space is needed, the bars will automatically scale

## Troubleshooting

### iCal URLs Not Working
- Ensure the URL is complete and includes the protocol (https://)
- Check that the URL is not expired (some platforms regenerate URLs)
- Verify the URL works by pasting it in a browser

### Calendar Not Updating
- After adding/editing properties, tap "Done" to save
- The calendar should refresh automatically
- If not, tap the refresh button (circular arrow) in the top bar

### Property Not Showing
- Ensure at least one iCal URL is entered for the property
- Check that the iCal URL contains valid booking data
- Verify the property was saved (tap "Done" in admin panel)

## Future Enhancements

Planned features:
- Custom property names (currently auto-generated)
- Reorder properties via drag-and-drop
- Export/import property configurations
- Bulk iCal URL updates
