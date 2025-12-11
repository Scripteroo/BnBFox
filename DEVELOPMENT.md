# BnBFox Development Guide

This document provides technical details for developers working on the BnBFox project.

## Development Environment

The project is configured for development on macOS using Xcode with the following specifications:

- **Xcode Version**: 15.0+
- **Swift Version**: 5.9+
- **iOS Deployment Target**: 16.0
- **Supported Devices**: iPhone only (iPad explicitly excluded)
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)

## Code Organization

The codebase follows a modular structure with clear separation of concerns:

### Models Layer

Models represent the core data structures of the application. All models are immutable value types (structs) conforming to relevant protocols.

**Platform.swift**: Defines the booking platform enumeration with associated display properties including colors and short names. This enum is used throughout the app to identify the source of bookings.

**Property.swift**: Represents a rental unit with its identifying information and associated calendar sources. Properties are uniquely identified by UUID and contain multiple calendar sources.

**CalendarSource.swift**: Links a platform to its iCal feed URL. Each property can have multiple sources from different platforms.

**Booking.swift**: Represents a single booking event with date range, guest information, and platform details. Includes helper methods for date calculations and overlap detection.

### Services Layer

Services handle business logic and external data operations. All services use the singleton pattern for global access.

**ICalService.swift**: Responsible for fetching and parsing iCal data from remote URLs. The parser handles the standard iCal format including VEVENT entries, date parsing, and guest name extraction. Key features include:
- Asynchronous data fetching using URLSession
- Line-by-line parsing of iCal format
- Support for both DATE and DATETIME formats
- Handling of line continuation in iCal files
- Platform-specific guest name extraction

**BookingService.swift**: Manages booking data aggregation from multiple sources. Uses Swift's structured concurrency (async/await) to fetch data from multiple calendar sources simultaneously. Provides filtering methods for date-based queries.

**PropertyService.swift**: Manages the list of available properties. Currently uses hardcoded property configurations but designed to support dynamic property management in the future.

### ViewModels Layer

ViewModels manage UI state and coordinate between services and views. They conform to ObservableObject for SwiftUI integration.

**CalendarViewModel.swift**: The main view model managing the calendar display state. Responsibilities include:
- Property selection and switching
- Booking data fetching and caching
- Loading state management
- Error handling and user feedback
- Month navigation and date calculations

The view model uses the @MainActor attribute to ensure all UI updates occur on the main thread.

### Views Layer

Views are built using SwiftUI and follow a component-based architecture. Each view is focused on a single responsibility.

**CalendarView.swift**: The root view of the application containing the header, calendar content, and loading/error states. Manages the overall layout and navigation structure.

**MonthView.swift**: Displays a single month calendar grid with day headers and booking information. Handles the calculation of calendar layout including empty cells for alignment.

**DayCell.swift**: Represents a single day in the calendar grid. Displays the day number, current day indicator, and booking badges. Limits visible bookings to prevent overflow.

**BookingBadge.swift**: A reusable component for displaying booking information as colored badges. Supports different corner rounding based on booking position (start, middle, end of multi-day booking).

**PropertySelectorView.swift**: A dropdown menu for switching between properties. Uses SwiftUI's Menu component for native iOS appearance.

### Utilities Layer

**DateExtensions.swift**: Provides extension methods on Date and Calendar types for common date operations used throughout the app. Includes methods for month navigation, date comparison, and calendar calculations.

## Key Technical Decisions

### SwiftUI Over UIKit

The project uses SwiftUI exclusively for several reasons:
- Modern declarative syntax reduces boilerplate
- Automatic view updates through data binding
- Built-in support for dark mode and accessibility
- Better integration with Swift's type system

### MVVM Architecture

The MVVM pattern provides clear separation between UI and business logic:
- Views are purely declarative and stateless
- ViewModels handle all state management and user interactions
- Models represent pure data without behavior
- Services encapsulate external dependencies

### Async/Await for Networking

Swift's structured concurrency is used for all asynchronous operations:
- Cleaner syntax compared to completion handlers
- Better error handling with try/catch
- Automatic cancellation support
- Task groups for concurrent operations

### Value Types for Models

All models use structs instead of classes:
- Immutability by default prevents bugs
- Value semantics make data flow predictable
- Better performance for small data structures
- Automatic Equatable and Hashable conformance

## Data Flow

The application follows a unidirectional data flow pattern:

1. **User Action**: User interacts with a view (e.g., selects a property)
2. **ViewModel Update**: View calls a method on the ViewModel
3. **Service Call**: ViewModel requests data from appropriate service
4. **Data Processing**: Service fetches and processes data
5. **State Update**: ViewModel updates its @Published properties
6. **View Refresh**: SwiftUI automatically re-renders affected views

This pattern ensures predictable state management and makes debugging easier.

## iCal Parsing Implementation

The iCal parser handles the standard RFC 5545 format with specific considerations:

### Format Support

The parser supports both DATE and DATETIME formats:
- `YYYYMMDD` for all-day events
- `YYYYMMDDTHHmmssZ` for timed events with UTC timezone
- `YYYYMMDDTHHmmss` for timed events without timezone

### Line Continuation

iCal files may contain line continuations (lines starting with space or tab). The parser correctly handles these by concatenating continued lines with the previous value.

### Guest Name Extraction

Different platforms format the SUMMARY field differently:
- **VRBO**: "Reserved - GuestName" (name extracted after dash)
- **AirBnB**: "Reserved" (no guest name provided)

The parser extracts guest names when available and returns nil otherwise.

### Error Handling

The parser is designed to be resilient:
- Invalid events are skipped rather than causing failures
- Date parsing errors result in event exclusion
- Network errors are caught and reported to the UI

## Performance Considerations

### Concurrent Data Fetching

Booking data from multiple sources is fetched concurrently using Swift's TaskGroup. This significantly reduces loading time compared to sequential fetching.

### Lazy Loading

The calendar uses LazyVStack and LazyVGrid to render only visible months and days. This prevents performance issues when displaying many months.

### In-Memory Caching

Parsed bookings are cached in the ViewModel to avoid re-parsing on every view update. The cache is invalidated when the user refreshes or switches properties.

## Testing Strategy

### Manual Testing

The app is designed for manual testing with real iCal data. Key test scenarios include:
- Loading bookings from multiple sources
- Switching between properties
- Refreshing data
- Scrolling through months
- Handling network errors

### Future Automated Testing

The architecture supports future addition of unit tests:
- Services can be tested independently with mock data
- ViewModels can be tested with mock services
- Date utilities can be tested with known inputs/outputs

## Git Workflow

The project is configured for Git version control with a standard workflow:

### Branch Strategy

- **main**: Stable production-ready code
- **develop**: Integration branch for features
- **feature/**: Individual feature branches

### Commit Guidelines

Commits should be atomic and descriptive:
- Use present tense ("Add feature" not "Added feature")
- Reference issue numbers when applicable
- Keep commits focused on a single change

### Xcode Integration

The project is configured to work with Xcode's built-in Git support:
- Source Control menu provides commit, push, and pull operations
- Commit window shows file diffs and allows selective staging
- Branch management available through Source Control navigator

## Adding New Features

### Adding a New Booking Platform

To add support for a new booking platform (e.g., Booking.com):

1. Add a new case to the `Platform` enum in `Platform.swift`
2. Define the platform's color and display name
3. Update `ICalService.swift` to handle platform-specific parsing if needed
4. Add calendar sources to properties in `PropertyService.swift`

### Adding Property Management UI

To allow users to add/edit properties dynamically:

1. Create a `PropertyManager` class to handle CRUD operations
2. Add persistence using UserDefaults or Core Data
3. Create a settings view with property management UI
4. Update `PropertyService` to load from persistent storage

### Adding Booking Details View

To show detailed information about a booking:

1. Create a `BookingDetailView.swift` in the Views folder
2. Add navigation from `DayCell` to the detail view
3. Display full booking information including dates, guest, and platform
4. Add actions like copying guest information or viewing in platform

## Code Style Guidelines

The project follows Swift's standard style guidelines:

### Naming Conventions

- Types: PascalCase (e.g., `CalendarViewModel`)
- Variables and functions: camelCase (e.g., `fetchBookings`)
- Constants: camelCase (e.g., `maxVisibleBookings`)
- Enums: PascalCase for type, camelCase for cases

### Formatting

- Indentation: 4 spaces (no tabs)
- Line length: Aim for 100 characters, hard limit at 120
- Braces: Opening brace on same line, closing brace on new line
- Spacing: One blank line between functions, two between types

### Documentation

- Use Swift's documentation comments (`///`) for public APIs
- Include parameter descriptions for complex functions
- Document non-obvious implementation decisions

## Debugging Tips

### Xcode Console

The app logs errors and important events to the console. Enable console output in Xcode to see:
- Network request failures
- iCal parsing errors
- Booking fetch progress

### Breakpoints

Set breakpoints in key locations:
- `ICalService.parseICalData`: Inspect parsed booking data
- `CalendarViewModel.loadBookings`: Check booking fetch flow
- `DayCell.body`: Examine booking display logic

### View Hierarchy

Use Xcode's View Hierarchy debugger to inspect the UI:
- **Debug > View Debugging > Capture View Hierarchy**
- Examine view layout and constraints
- Check for overlapping or hidden views

## Known Limitations

### Current Constraints

- Properties are hardcoded in `PropertyService`
- No offline support (requires internet connection)
- No push notifications for new bookings
- Limited error recovery options
- No booking conflict detection

### Platform Limitations

- AirBnB does not provide guest names in iCal feeds
- iCal feeds may have delays in updating
- Some booking platforms rate-limit iCal requests

## Future Technical Improvements

### Persistence Layer

Add local data storage using SwiftData or Core Data:
- Cache bookings for offline access
- Store user preferences
- Track booking history

### Network Layer

Enhance networking with URLSession configuration:
- Request caching
- Retry logic for failed requests
- Background fetch for automatic updates

### Testing Infrastructure

Implement comprehensive testing:
- Unit tests for services and view models
- UI tests for critical user flows
- Snapshot tests for view components

### Performance Monitoring

Add instrumentation for performance tracking:
- Measure data fetch times
- Monitor memory usage
- Track view rendering performance

## Resources

### Apple Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)

### iCal Format

- [RFC 5545 - iCalendar Specification](https://tools.ietf.org/html/rfc5545)
- [iCal Format Guide](https://icalendar.org/)

### Swift Style

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)
