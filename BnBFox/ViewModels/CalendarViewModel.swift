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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentMonth: Date = Date()
    
    private let propertyService = PropertyService.shared
    let bookingService = BookingService.shared
    
    var properties: [Property] {
        return propertyService.getAllProperties()
    }
    
    func loadBookings() async {
        isLoading = true
        errorMessage = nil
        
        var allBookings: [Booking] = []
        
        // Fetch bookings from all properties
        for property in properties {
            let fetchedBookings = await bookingService.fetchAllBookings(for: property)
            allBookings.append(contentsOf: fetchedBookings)
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
    
    func getMonthsToDisplay(count: Int = 6) -> [Date] {
        var months: [Date] = []
        for i in 0..<count {
            if let month = Calendar.current.date(byAdding: .month, value: i, to: currentMonth.startOfMonth()) {
                months.append(month)
            }
        }
        return months
    }
}
