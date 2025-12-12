# BnBFox Product Backlog

## Planned Features

### 1. Completion Photos ✨
**Priority:** High  
**Status:** Planned for v4.0

**Description:**
Allow cleaning staff to take a photo from the front door as they lock up the apartment after cleaning. Photo is sent to property owner via the app.

**Technical Requirements:**
- Camera integration using `UIImagePickerController`
- Photo storage (cloud-based: Firebase/AWS S3)
- Backend API for photo upload
- Owner notification system
- Photo history/gallery in owner interface

**User Stories:**
- As a cleaner, I want to take a completion photo to document that I finished the job
- As an owner, I want to receive completion photos to verify cleaning was done

---

### 2. Damage Reporting 🔧
**Priority:** High  
**Status:** Planned for v4.0

**Description:**
If cleaning staff spots anything damaged or broken, they can upload a photo with description. Owner gets pinged immediately with urgent notification.

**Technical Requirements:**
- Camera integration (same as Completion Photos)
- Damage category selection (broken, stained, missing, etc.)
- Text description field
- Urgent notification to owner
- Damage tracking and resolution workflow
- Backend API for damage reports

**User Stories:**
- As a cleaner, I want to report damage I find so the owner is aware
- As an owner, I want immediate notification of damage so I can address it before next guest

---

### 3. Host/Owner Backend System 🖥️
**Priority:** Critical (Required for features #1 and #2)  
**Status:** Planned for v4.0

**Description:**
Backend infrastructure to support communication between cleaning staff and property owners.

**Technical Components:**
- User authentication (cleaners vs. owners)
- Cloud storage for photos
- Push notification system
- Owner dashboard (web or separate app)
- Photo and damage report management
- User roles and permissions

**Technology Stack Options:**
- Firebase (easiest, all-in-one)
- AWS (S3 + Lambda + DynamoDB + SNS)
- Custom backend (Node.js/Python + PostgreSQL)

**User Stories:**
- As an owner, I want a dashboard to see all my properties and staff activity
- As a cleaner, I want to be connected to the properties I service
- As an owner, I want to receive real-time notifications about my properties

---

## Completed Features ✅

### v3.3 - Cleaning Day Alerts
- Local notifications for checkout/cleaning days
- Same-day turnover urgent flagging
- Configurable alert time and sound
- Settings panel with upcoming cleanings list
- Automatic scheduling based on calendar

### v3.2 - Progressive Loading
- Fast initial load (current month first)
- Infinite scroll with 19 months
- Auto-scroll to current month

### v3.1 - UI Polish
- Fixed duplicate headers
- Clean property detail views

### v3.0 - Core Calendar
- Multi-property calendar
- iCal integration (Airbnb, VRBO, Booking.com)
- Color-coded properties
- Admin panel for configuration
- 15-minute caching

---

## Future Considerations 💡

### v5.0+ Ideas
- **Cleaning Checklists:** Pre-defined tasks for each property
- **Time Tracking:** Log start/end times for cleaning sessions
- **Supply Inventory:** Track cleaning supplies and reorder alerts
- **Guest Communication:** Automated messages for check-in/check-out
- **Revenue Dashboard:** Booking analytics and income tracking
- **Multi-language Support:** Spanish, French, etc.
- **Offline Mode:** Work without internet, sync later
- **Apple Watch App:** Quick glance at today's cleanings

---

## Version Roadmap

- **v3.3** (Current): Cleaning Day Alerts ✅
- **v4.0** (Q1 2026): Backend + Completion Photos + Damage Reporting
- **v5.0** (Q2 2026): Advanced features (checklists, time tracking, etc.)

---

*Last Updated: December 12, 2025*
