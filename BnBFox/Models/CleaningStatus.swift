//
//  CleaningStatus.swift
//  BnBFox
//
//  Fixed to only create cleaning tasks for TODAY's checkouts
//

import Foundation

/// Represents the cleaning status of a property for a specific booking period
struct CleaningStatus: Codable, Identifiable {
    let id: UUID
    let propertyName: String
    let date: Date
    let bookingId: String  // Links to the booking this cleaning is for
    var status: Status
    var lastUpdated: Date
    
    enum Status: String, Codable {
        case pending = "pending"      // Gray - Not yet started
        case todo = "todo"            // Red - Needs cleaning (checkout occurred)
        case inProgress = "inProgress" // Amber - Cleaner is working
        case done = "done"            // Green - Cleaning complete
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .todo: return "To do"
            case .inProgress: return "Doing..."
            case .done: return "Done!"
            }
        }
        
        var colorName: String {
            switch self {
            case .pending: return "gray"
            case .todo: return "red"
            case .inProgress: return "orange"
            case .done: return "green"
            }
        }
    }
    
    init(id: UUID = UUID(), propertyName: String, date: Date, bookingId: String, status: Status = .pending) {
        self.id = id
        self.propertyName = propertyName
        self.date = date
        self.bookingId = bookingId
        self.status = status
        self.lastUpdated = Date()
    }
    
    mutating func updateStatus(_ newStatus: Status) {
        self.status = newStatus
        self.lastUpdated = Date()
    }
}

/// Manages cleaning status persistence
class CleaningStatusManager: ObservableObject {
    static let shared = CleaningStatusManager()
    
    @Published private(set) var statuses: [CleaningStatus] = []
    
    private let storageKey = "cleaningStatuses"
    private var badgeUpdateTask: Task<Void, Never>?
    
    private init() {
        loadStatuses()
    }
    
    /// Get status for a specific property and date
    func getStatus(propertyName: String, date: Date) -> CleaningStatus? {
        let calendar = Calendar.current
        return statuses.first { status in
            status.propertyName == propertyName &&
            calendar.isDate(status.date, inSameDayAs: date)
        }
    }
    
    /// Create or update status for a property (async to prevent blocking)
    @MainActor
    func setStatus(propertyName: String, date: Date, bookingId: String, status: CleaningStatus.Status) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("⏱️ setStatus START for \(propertyName)")
        
        // Update the status array
        if let index = statuses.firstIndex(where: { $0.propertyName == propertyName && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            statuses[index].updateStatus(status)
        } else {
            let newStatus = CleaningStatus(propertyName: propertyName, date: date, bookingId: bookingId, status: status)
            statuses.append(newStatus)
        }
        print("⏱️ After array update: \(Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000))ms")
        
        // Notify views - this will trigger @ObservedObject updates
        objectWillChange.send()
        print("⏱️ After objectWillChange: \(Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000))ms")
        
        // Immediately notify calendar dots to refresh (on main thread)
        NotificationCenter.default.post(name: NSNotification.Name("CleaningStatusChanged"), object: nil)
        print("⏱️ After notification: \(Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000))ms")
        
        // Do heavy work off main thread (fire and forget - don't wait)
        Task.detached(priority: .userInitiated) {
            // Invalidate cache so calendar dots recalculate
            //CleaningGapCache.shared.invalidateCache()
            
            // Save to disk
            await MainActor.run {
                self.saveStatuses()
            }
        }
        
        print("⏱️ After async work: \(Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000))ms")
        
        // Badge updates are debounced and handled separately
        scheduleBadgeUpdate()
        
        print("⏱️ setStatus COMPLETE: \(Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000))ms")
    }
    
    /// Schedule a debounced badge update
    /// Cancels any pending update and schedules a new one after 1 second
    /// This prevents the expensive BadgeManager.updateBadge() from blocking on every status change
    private func scheduleBadgeUpdate() {
        // Cancel any pending badge update
        badgeUpdateTask?.cancel()
        
        // Schedule a new badge update after 1 second
        badgeUpdateTask = Task {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                // Only update if not cancelled
                if !Task.isCancelled {
                    await MainActor.run {
                        BadgeManager.shared.updateBadge()
                    }
                }
            } catch {
                // Task was cancelled, do nothing
            }
        }
    }
    
    /// Get all statuses that need attention (todo or inProgress)
    func getPendingStatuses() -> [CleaningStatus] {
        return statuses.filter { $0.status == .todo || $0.status == .inProgress }
            .sorted { $0.date < $1.date }
    }
    
    /// Clear all cleaning statuses
    func clearAll() {
        statuses.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        objectWillChange.send()
        BadgeManager.shared.updateBadge()
    }
    
    /// Automatically create cleaning tasks for TODAY's checkouts only
    func autoCreateCleaningTasks() async {
        let bookings = await PropertyService.shared.getAllBookings()
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        print("🔄 Auto-creating cleaning tasks for TODAY only...")
        
        var tasksCreated = 0
        
        // Group bookings by property and checkout date
        var checkoutsByProperty: [UUID: [Date: [Booking]]] = [:]
        
        for booking in bookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            
            // ONLY process if checkout is TODAY
            guard calendar.isDate(checkoutDate, inSameDayAs: today) else {
                continue
            }
            
            if checkoutsByProperty[booking.propertyId] == nil {
                checkoutsByProperty[booking.propertyId] = [:]
            }
            if checkoutsByProperty[booking.propertyId]![checkoutDate] == nil {
                checkoutsByProperty[booking.propertyId]![checkoutDate] = []
            }
            checkoutsByProperty[booking.propertyId]![checkoutDate]!.append(booking)
        }
        
        // Check each property's checkouts
        for (propertyId, dateBookings) in checkoutsByProperty {
            guard let property = PropertyService.shared.getProperty(by: propertyId) else { continue }
            
            for (checkoutDate, bookingsOnDate) in dateBookings {
                // Check if checkout time (10 AM) has passed
                var checkoutTime = calendar.dateComponents([.year, .month, .day], from: checkoutDate)
                checkoutTime.hour = 10
                checkoutTime.minute = 0
                
                guard let checkoutDateTime = calendar.date(from: checkoutTime),
                      checkoutDateTime <= now else {
                    continue // Checkout hasn't happened yet
                }
                
                // Check if we already have a status for this property/date
                let existingStatus = getStatus(propertyName: property.displayName, date: checkoutDate)
                
                // Only create if no status exists OR status is still pending
                if existingStatus == nil || existingStatus?.status == .pending {
                    // Use the first booking's ID
                    let bookingId = bookingsOnDate.first?.id ?? "unknown"
                    
                    await setStatus(
                        propertyName: property.displayName,
                        date: checkoutDate,
                        bookingId: bookingId,
                        status: .todo
                    )
                    
                    tasksCreated += 1
                    print("✅ Created cleaning task for \(property.shortName) on \(checkoutDate)")
                }
            }
        }
        
        if tasksCreated > 0 {
            print("✅ Auto-created \(tasksCreated) cleaning tasks for TODAY")
        } else {
            print("ℹ️  No new cleaning tasks to create for TODAY")
        }
    }
    
    /// Clean up old statuses (older than 30 days)
    func cleanupOldStatuses() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        statuses.removeAll { $0.date < thirtyDaysAgo }
        saveStatuses()
    }
    
    private func loadStatuses() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CleaningStatus].self, from: data) else {
            return
        }
        statuses = decoded
    }
    
    private func saveStatuses() {
        if let encoded = try? JSONEncoder().encode(statuses) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

