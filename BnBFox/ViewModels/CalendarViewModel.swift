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
        
        if monthsToShow == 1 {
            // Initial load: show only current month for speed
            months.append(currentMonth.startOfMonth())
        } else {
            // Full load: show 6 months back to 12 months forward
            let startMonth = calendar.date(byAdding: .month, value: -6, to: currentMonth.startOfMonth()) ?? currentMonth
            
            for i in 0..<monthsToShow {
                if let month = calendar.date(byAdding: .month, value: i, to: startMonth) {
                    months.append(month)
                }
            }
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
