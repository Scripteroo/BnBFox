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
    @Published var selectedProperty: Property?
    @Published var bookings: [Booking] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentMonth: Date = Date()
    
    private let propertyService = PropertyService.shared
    private let bookingService = BookingService.shared
    
    var properties: [Property] {
        return propertyService.getAllProperties()
    }
    
    init() {
        // Set the first property as default
        self.selectedProperty = properties.first
    }
    
    func loadBookings() async {
        guard let property = selectedProperty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedBookings = await bookingService.fetchAllBookings(for: property)
            self.bookings = fetchedBookings
        } catch {
            errorMessage = "Failed to load bookings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadBookings()
    }
    
    func selectProperty(_ property: Property) {
        guard property.id != selectedProperty?.id else { return }
        selectedProperty = property
        Task {
            await loadBookings()
        }
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
