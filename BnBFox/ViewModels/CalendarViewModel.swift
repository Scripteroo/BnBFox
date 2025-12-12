//
//  CalendarViewModel.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var currentMonth: Date = Date()
    @Published var monthsToShow: Int = 1  // Start with 1 month for fast initial load
    
    private let propertyService = PropertyService.shared
    let bookingService = BookingService.shared
    
    var properties: [Property] {
        return propertyService.getAllProperties()
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
        self.bookings = allBookings.sorted { $0.startDate < $1.startDate }
        isLoading = false
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
        
        if monthsToShow == 1 {
            // Initial load: show only current month for speed
            months.append(currentMonthStart)
        } else {
            // Full load: Start at current month, then add forward months, then prepend history
            // This ensures current month is at the top of the list naturally
            
            // Add current month
            months.append(currentMonthStart)
            
            // Add 12 months forward
            for i in 1...12 {
                if let month = calendar.date(byAdding: .month, value: i, to: currentMonthStart) {
                    months.append(month)
                }
            }
            
            // Prepend 6 months back (in reverse order so they appear before current)
            var historyMonths: [Date] = []
            for i in 1...6 {
                if let month = calendar.date(byAdding: .month, value: -i, to: currentMonthStart) {
                    historyMonths.insert(month, at: 0)
                }
            }
            months = historyMonths + months
        }
        return months
    }
    
    func expandMonthsAfterInitialLoad() {
        // Expand to show full range (6 months back + 12 months forward = 18 months)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second delay
            withAnimation {
                monthsToShow = 19  // 6 back + current + 12 forward
            }
        }
    }
}
