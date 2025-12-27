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
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            Logger.log("Using cached bookings for \(property.shortName)")
            return cached.bookings
        }
        
        var allBookings: [Booking] = []
        
        // Get sources - if property is corrupted, this will crash
        // The only way to fix this is to clear the app's UserDefaults data
        // To do that: Delete the app from simulator/device and reinstall, OR
        // In Xcode: Product > Scheme > Edit Scheme > Run > Arguments > Add "UIApplicationSupportsMultipleScenes" = NO
        // Then add code to clear UserDefaults on first launch after corruption
        let sources = property.sources
        
        // Fetch bookings from all sources concurrently
        await withTaskGroup(of: [Booking].self) { group in
            // Iterate using for-in - Swift handles bounds checking safely
            for source in sources {
                group.addTask {
                    do {
                        Logger.log("📥 Fetching bookings from \(source.platform.displayName) for \(property.shortName) from: \(source.url.absoluteString)")
                        let icalData = try await self.icalService.fetchICalData(from: source.url)
                        let bookings = self.icalService.parseICalData(
                            icalData,
                            platform: source.platform,
                            propertyId: property.id
                        )
                        Logger.log("✅ Found \(bookings.count) bookings from \(source.platform.displayName) for \(property.shortName)")
                        return bookings
                    } catch {
                        Logger.log("❌ Error fetching bookings from \(source.platform.displayName) for \(property.shortName): \(error.localizedDescription)")
                        Logger.log("   URL: \(source.url.absoluteString)")
                        return []
                    }
                }
            }
            
            // Use individual appends instead of append(contentsOf) to avoid calling .count
            for await bookings in group {
                for booking in bookings {
                    allBookings.append(booking)
                }
            }
        }
        
        // Sort bookings by start date
        let sortedBookings = allBookings.sorted { $0.startDate < $1.startDate }
        
        // Cache the results
        cache[cacheKey] = (bookings: sortedBookings, timestamp: Date())
        Logger.log("Cached bookings for \(property.shortName)")
        
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
        Logger.log("Cleared booking cache for property: \(cacheKey)")
    }
    
    // Clear cache for all properties
    func clearAllCache() {
        cache.removeAll()
        Logger.log("Cleared all booking cache")
    }
    
}

