//
//  CleaningStatus.swift
//  BnBFox
//
//  Created on 12/15/25.
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
    
    /// Create or update status for a property
    func setStatus(propertyName: String, date: Date, bookingId: String, status: CleaningStatus.Status) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let index = self.statuses.firstIndex(where: {
                $0.propertyName == propertyName &&
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }) {
                self.statuses[index].updateStatus(status)
            } else {
                let newStatus = CleaningStatus(propertyName: propertyName, date: date, bookingId: bookingId, status: status)
                self.statuses.append(newStatus)
            }
            self.saveStatuses()
            
            // Update app badge to reflect pending count
            BadgeManager.shared.updateBadge()
        }
    }
    
    /// Get all statuses that need attention (todo or inProgress)
    func getPendingStatuses() -> [CleaningStatus] {
        return statuses.filter { $0.status == .todo || $0.status == .inProgress }
            .sorted { $0.date < $1.date }
    }
    
    /// Clean up old statuses (older than 30 days)
    func cleanupOldStatuses() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            self.statuses.removeAll { $0.date < thirtyDaysAgo }
            self.saveStatuses()
        }
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


