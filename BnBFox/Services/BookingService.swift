//
//  BookingService.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation
import SwiftUI

class BookingService: ObservableObject {
    static let shared = BookingService()
    
    private let icalService = ICalService.shared
    
    private init() {}
    
    func fetchAllBookings(for property: Property) async -> [Booking] {
        var allBookings: [Booking] = []
        
        // Fetch bookings from all sources concurrently
        await withTaskGroup(of: [Booking].self) { group in
            for source in property.sources {
                group.addTask {
                    do {
                        let icalData = try await self.icalService.fetchICalData(from: source.url)
                        let bookings = self.icalService.parseICalData(
                            icalData,
                            platform: source.platform,
                            propertyId: property.id
                        )
                        return bookings
                    } catch {
                        print("Error fetching bookings from \(source.platform.displayName): \(error)")
                        return []
                    }
                }
            }
            
            for await bookings in group {
                allBookings.append(contentsOf: bookings)
            }
        }
        
        // Sort bookings by start date
        return allBookings.sorted { $0.startDate < $1.startDate }
    }
    
    func getBookings(for date: Date, from bookings: [Booking]) -> [Booking] {
        return bookings.filter { $0.overlapsDate(date) }
    }
    
    func getBookings(in dateRange: ClosedRange<Date>, from bookings: [Booking]) -> [Booking] {
        return bookings.filter { booking in
            // Check if booking overlaps with the date range
            let bookingRange = booking.startDate...booking.endDate
            return bookingRange.overlaps(dateRange)
        }
    }
}
