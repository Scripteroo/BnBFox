# BnBFox v1.0 Release Notes

**Release Date:** December 13, 2025  
**Platform:** iOS (iPhone)  
**Target Users:** Cleaning crew for Bed & Breakfast properties

---

## Overview

BnBFox v1.0 is a production-ready iOS application designed for cleaning crews managing multiple rental properties. The app integrates iCal feeds from Airbnb, VRBO, and Booking.com to provide a unified calendar view with intelligent cleaning day alerts.

---

## Core Features

### 📅 Multi-Property Calendar
- **Three Properties Configured:**
  - Kawama C-2
  - Kawama E-5
  - Kawama C-5
- **iCal Feed Integration:** Automatic synchronization with Airbnb and VRBO
- **Progressive Loading:** Shows current month immediately, then expands to 6 months back + 12 months forward
- **15-Minute Cache:** Optimized performance with intelligent data caching

### 🔔 Smart Cleaning Alerts
- **Automatic Scheduling:** Alerts triggered at 8:00 AM on checkout/cleaning days
- **Same-Day Turnover Detection:** URGENT flag for tight turnaround situations
- **Configurable Settings:**
  - Toggle alerts on/off per property
  - Enable/disable notification sounds
  - View upcoming cleanings list with priority sorting

### 📢 New Booking Alerts
- **Real-Time Detection:** Identifies new bookings added in the current month
- **Property-Specific Notifications:** Clear indication of which property has a new booking
- **Toggle Control:** Enable/disable in settings

### 🎨 Professional UI/UX
- **VRBO-Style Calendar:** Clean, professional appearance
- **Visual Indicators:**
  - Blue underlined property labels (clickable)
  - Bold day headers (M-S), red Sunday
  - Full green backgrounds for cleaning days
  - Blue underlined dates with bookings (clickable)
- **Optimized Layout:** Entire month fits on one screen with scrollability indication
- **Expandable Cells:** Days automatically accommodate multiple property bookings

---

## Technical Specifications

### Architecture
- **Framework:** SwiftUI
- **Language:** Swift
- **Minimum iOS Version:** iOS 15.0
- **Device Support:** iPhone (optimized for all sizes)

### Key Components
- **BnBFoxApp.swift:** Main app entry point
- **CalendarViewModel.swift:** Calendar data management and booking refresh logic
- **CalendarView.swift:** Main calendar interface
- **MonthView.swift:** Individual month display with day cells
- **SettingsView.swift:** Alert configuration panel
- **NotificationService.swift:** Local notification management
- **PropertyService.swift:** Property and booking data management
- **BookingService.swift:** iCal feed fetching and parsing

### Data Sources
- Airbnb iCal feeds
- VRBO iCal feeds
- Booking.com iCal feeds (configured for future use)

---

## Setup Requirements

### Manual Configuration Needed
1. **Sea Turtle Animation:** Add `sea-turtle-swimming.mov` to project (optional loading animation)
2. **iCal URLs:** Update property iCal feed URLs in PropertyService.swift for your properties

### Permissions Required
- **Notifications:** For cleaning day alerts
- **Network Access:** For iCal feed synchronization

---

## Known Limitations

### Current Version
- No backend server (all data from iCal feeds)
- No host interface (cleaning crew view only)
- No completion photo upload (planned for future release)
- No damage reporting (planned for future release)

### Console Messages
- ForEach duplicate ID warnings for day headers (cosmetic, no functional impact)
- Network timeout messages (normal iOS behavior)
- FigApplicationStateMonitor errors (iOS system messages, can be ignored)

---

## Future Roadmap

### Planned Features (Product Backlog)
1. **Completion Photos:** Upload before/after cleaning photos
2. **Damage Reporting:** Report and document property damage
3. **Backend System:** Cloud storage and synchronization
4. **Host Interface:** Property owner dashboard
5. **Deep Linking:** Tap notification → Navigate to specific cleaning task page
6. **Checklist System:** Interactive cleaning checklists per property

---

## Version History

- **v3.5:** Cleaning Day Alerts and New Booking Alerts
- **v4.0:** Comprehensive UI/UX improvements
- **v4.1:** Red Sunday header
- **v1.0:** Production release with bug fixes and optimizations

---

## Credits

**Developed for:** Kawama Rental Properties  
**Target Users:** Cleaning crew management  
**Development Period:** December 2025  

---

## Support

For issues, feature requests, or questions:
- Check TROUBLESHOOTING.md for common issues
- Review UI_IMPROVEMENTS_V4.md for design documentation
- Contact property management for operational questions

---

**Status:** ✅ Production Ready  
**Build Warnings:** None  
**Known Bugs:** None  
**Performance:** Optimized with 15-minute caching
