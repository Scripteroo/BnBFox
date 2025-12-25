//
//  BookingService.swift
//  BnBFox
//
//  Updated with public getCachedBookings method
//

import Foundation
import SwiftUI

class BookingService: ObservableObject {
    static let shared = BookingService()
    
    private let icalService = ICalService.shared
    private var cache: [String: (bookings: [Booking], timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 900 // 15 minutes
    
    private init() {}
    
    func fetchAllBookings(for property: Property) async -> [Booking] {
        // Check cache first
        let cacheKey = property.id.uuidString
        
        // Safely access cache with defensive check
        if let cached = cache[cacheKey] {
            // Verify cached data structure is valid
            if Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
                print("Using cached bookings for \(property.shortName)")
                return cached.bookings
            }
        }
        
        var allBookings: [Booking] = []
        
        // Guard against empty or invalid sources
        // Ensure sources is actually an array (defensive check)
        guard property.sources is [CalendarSource], !property.sources.isEmpty else {
            print("No sources configured for property \(property.shortName)")
            // Cache empty result to avoid repeated checks
            cache[cacheKey] = (bookings: [], timestamp: Date())
            return []
        }
        
        // Fetch bookings from all sources concurrently
        await withTaskGroup(of: [Booking].self) { group in
            for source in property.sources {
                group.addTask {
                    do {
                        print("📥 Fetching bookings from \(source.platform.displayName) for \(property.shortName) from: \(source.url.absoluteString)")
                        let icalData = try await self.icalService.fetchICalData(from: source.url)
                        let bookings = self.icalService.parseICalData(
                            icalData,
                            platform: source.platform,
                            propertyId: property.id
                        )
                        print("✅ Found \(bookings.count) bookings from \(source.platform.displayName) for \(property.shortName)")
                        return bookings
                    } catch {
                        print("❌ Error fetching bookings from \(source.platform.displayName) for \(property.shortName): \(error.localizedDescription)")
                        print("   URL: \(source.url.absoluteString)")
                        return []
                    }
                }
            }
            
            for await bookings in group {
                allBookings.append(contentsOf: bookings)
            }
        }
        
        // Sort bookings by start date
        let sortedBookings = allBookings.sorted { $0.startDate < $1.startDate }
        
        // Cache the results
        cache[cacheKey] = (bookings: sortedBookings, timestamp: Date())
        print("Cached bookings for \(property.shortName)")
        
        return sortedBookings
    }
    
    // Public method to get cached bookings synchronously
    func getCachedBookings(for property: Property) -> [Booking] {
        let cacheKey = property.id.uuidString
        if let cached = cache[cacheKey] {
            return cached.bookings
        }
        return []
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
    
    // Clear cache for a specific property
    func clearCache(for propertyId: UUID) {
        let cacheKey = propertyId.uuidString
        cache.removeValue(forKey: cacheKey)
        print("Cleared booking cache for property: \(cacheKey)")
    }
    
    // Clear cache for all properties
    func clearAllCache() {
        cache.removeAll()
        print("Cleared all booking cache")
    }
}

