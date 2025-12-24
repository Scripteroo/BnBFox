//
//  CalendarViewModel.swift
//  BnBShift
//
//  Created on 12/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var currentMonth: Date = Date()
    
    private let propertyService = PropertyService.shared
    let bookingService = BookingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var properties: [Property] {
        return propertyService.getAllProperties()
    }
    
    init() {
        // Observe PropertyService changes to refresh calendar when properties are updated
        propertyService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadBookings() async {
        isLoading = true
        errorMessage = nil
        
        var allBookings: [Booking] = []
        
        // Fetch bookings from all properties concurrently for better performance
        await withTaskGroup(of: [Booking].self) { group in
            for property in properties {
                group.addTask {
                    await self.bookingService.fetchAllBookings(for: property)
                }
            }
            
            for await fetchedBookings in group {
                allBookings.append(contentsOf: fetchedBookings)
            }
        }
        
        // Sort by start date
        let sortedBookings = allBookings.sorted { $0.startDate < $1.startDate }
        
        // Check for new bookings before updating
        if !self.bookings.isEmpty {
            // Not first load, check for new bookings
            NotificationService.shared.checkForNewBookings(sortedBookings)
        } else {
            // First load, initialize tracking
            NotificationService.shared.initializeBookingTracking(sortedBookings)
        }
        
        self.bookings = sortedBookings
        isLoading = false
        
        // Schedule cleaning alerts if enabled
        if AppSettings.shared.cleaningAlertsEnabled {
            NotificationService.shared.scheduleCleaningAlerts()
        }
    }
    
    func refreshData() async {
        await loadBookings()
    }
    
    func getBookings(for date: Date) -> [Booking] {
        return bookingService.getBookings(for: date, from: bookings)
    }
    
    func getMonthsToDisplay() -> [Date] {
        var months: [Date] = []
        let calendar = Calendar.current
        let currentMonthStart = currentMonth.startOfMonth()
        
        // Optimized range: 2 months back + current + 12 months forward
        // Add 2 months back
        for i in (1...2).reversed() {
            if let month = calendar.date(byAdding: .month, value: -i, to: currentMonthStart) {
                months.append(month)
            }
        }
        
        // Add current month
        months.append(currentMonthStart)
        
        // Add 12 months forward
        for i in 1...12 {
            if let month = calendar.date(byAdding: .month, value: i, to: currentMonthStart) {
                months.append(month)
            }
        }
        
        return months
    }
}


