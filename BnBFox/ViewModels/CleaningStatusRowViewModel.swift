//
//  CleaningStatusRowViewModel.swift
//  BnBFox
//
//  Per-row view model for cleaning status items
//  Implements Copilot's recommendation for granular updates
//

import Foundation
import SwiftUI

/// View model for a single cleaning status row
/// Each row has its own ObservableObject to prevent unnecessary re-renders
final class CleaningStatusRowViewModel: ObservableObject, Identifiable {
    // MARK: - Published Properties
    @Published private(set) var status: CleaningStatus
    
    // MARK: - Computed Properties
    var id: String {
        "\(status.propertyName)-\(status.date.timeIntervalSince1970)"
    }
    
    var propertyName: String {
        status.propertyName
    }
    
    var date: Date {
        status.date
    }
    
    var bookingId: String {
        status.bookingId
    }
    
    var currentStatus: CleaningStatus.Status {
        status.status
    }
    
    // MARK: - Initialization
    init(status: CleaningStatus) {
        self.status = status
    }
    
    // MARK: - Public Methods
    
    /// Update cleaning status asynchronously
    /// Uses optimistic updates and async/await to prevent main thread blocking
    func updateStatus(to newStatus: CleaningStatus.Status, showToast: @escaping (String, String) -> Void) async {
        // Optimistic update on main actor - UI responds immediately
        await MainActor.run {
            self.status.updateStatus(newStatus)
        }
        
        // Show toast immediately
        await MainActor.run {
            switch newStatus {
            case .inProgress:
                showToast("I'm on my way", "🚗")
            case .done:
                showToast("Clean and Ready!", "✨")
            case .todo:
                break // No toast for marking dirty
            @unknown default:
                break
            }
        }
        
        // Perform actual update asynchronously
        // setStatus is now @MainActor async, so it handles threading properly
        await CleaningStatusManager.shared.setStatus(
            propertyName: self.status.propertyName,
            date: self.status.date,
            bookingId: self.status.bookingId,
            status: newStatus
        )
        
        // Note: If the update fails, we could revert here
        // For now, we trust that setStatus succeeds (it's local storage)
    }
    
    /// Update the status from external source (e.g., notification)
    func refresh(with newStatus: CleaningStatus) {
        self.status = newStatus
    }
    
    /// Get the day's activity type (checkout, checkin, or both)
    var dayActivityType: DayActivityType {
        let calendar = Calendar.current
        let cleaningDate = calendar.startOfDay(for: status.date)
        
        // Get all properties to find the matching one
        let properties = PropertyService.shared.getAllProperties()
        guard let property = properties.first(where: {
            $0.name == status.propertyName ||
            $0.displayName == status.propertyName ||
            $0.shortName == status.propertyName
        }) else {
            return .checkoutOnly
        }
        
        // Get cached bookings for this property
        let bookings = BookingService.shared.getCachedBookings(for: property)
        
        var hasCheckout = false
        var hasCheckin = false
        
        for booking in bookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            let checkinDate = calendar.startOfDay(for: booking.startDate)
            
            if checkoutDate == cleaningDate {
                hasCheckout = true
            }
            if checkinDate == cleaningDate {
                hasCheckin = true
            }
        }
        
        if hasCheckout && hasCheckin {
            return .both
        } else if hasCheckin {
            return .checkinOnly
        } else {
            return .checkoutOnly
        }
    }
}

enum DayActivityType {
    case checkoutOnly
    case checkinOnly
    case both
}

