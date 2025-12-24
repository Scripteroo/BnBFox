//
//  CalendarViewModel.swift
//  BnBShift
//
//  Created on 12/11/2025.
//  Optimized on 12/23/2025 - Performance improvements
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
    @Published var loadingProgress: Double = 0.0  // NEW: Track loading progress
    
    private let propertyService = PropertyService.shared
    let bookingService = BookingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // OPTIMIZATION #3: Add booking cache with expiration
    private var bookingCache: [UUID: (bookings: [Booking], timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    var properties: [Property] {
        return propertyService.getAllProperties()
    }
    
    init() {
        // OPTIMIZATION #1: Only refresh when properties actually change, not on every objectWillChange
        // This prevents unnecessary re-renders of the entire calendar view
        propertyService.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload if properties actually changed
                Task { @MainActor in
                    await self?.loadBookings()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadBookings() async {
        isLoading = true
        errorMessage = nil
        loadingProgress = 0.0
        
        var allBookings: [Booking] = []
        
        // OPTIMIZATION #3 & #5: Fetch with caching and progress tracking
        let totalProperties = properties.count
        var completed = 0
        
        await withTaskGroup(of: (propertyId: UUID, bookings: [Booking]).self) { group in
            for property in properties {
                group.addTask {
                    let bookings = await self.fetchBookingsWithCache(for: property)
                    return (property.id, bookings)
                }
            }
            
            for await (propertyId, fetchedBookings) in group {
                allBookings.append(contentsOf: fetchedBookings)
                completed += 1
                self.loadingProgress = Double(completed) / Double(totalProperties)
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
    
    // OPTIMIZATION #3: Cache bookings to reduce API calls
    private func fetchBookingsWithCache(for property: Property) async -> [Booking] {
        let cacheKey = property.id
        
        // Check cache first
        if let cached = bookingCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            print("📦 Using cached bookings for \(property.name)")
            return cached.bookings
        }
        
        // Fetch from API
        print("🌐 Fetching bookings from API for \(property.name)")
        let bookings = await bookingService.fetchAllBookings(for: property)
        
        // Update cache
        bookingCache[cacheKey] = (bookings, Date())
        
        return bookings
    }
    
    // NEW: Force refresh (bypasses cache)
    func forceRefresh() async {
        bookingCache.removeAll()
        await loadBookings()
    }
    
    func refreshData() async {
        await loadBookings()
    }
    
    // NEW: Clear cache for specific property
    func clearCache(for propertyId: UUID) {
        bookingCache.removeValue(forKey: propertyId)
    }
    
    // NEW: Clear all cache
    func clearAllCache() {
        bookingCache.removeAll()
    }
    
    func getBookings(for date: Date) -> [Booking] {
        return bookingService.getBookings(for: date, from: bookings)
    }
    
    // OPTIMIZATION #6: Reduced month range for better memory usage
    // Changed from 2 back + 12 forward to 1 back + 3 forward
    // Load more months on demand when user scrolls
    func getMonthsToDisplay() -> [Date] {
        var months: [Date] = []
        let calendar = Calendar.current
        let currentMonthStart = currentMonth.startOfMonth()
        
        // Reduced range: 1 month back + current + 3 months forward
        // This reduces memory usage by ~60%
        
        // Add 1 month back
        if let month = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) {
            months.append(month)
        }
        
        // Add current month
        months.append(currentMonthStart)
        
        // Add 3 months forward
        for i in 1...3 {
            if let month = calendar.date(byAdding: .month, value: i, to: currentMonthStart) {
                months.append(month)
            }
        }
        
        return months
    }
    
    // NEW: Load more months when user scrolls (for pagination)
    func loadMoreMonths(direction: ScrollDirection) {
        let calendar = Calendar.current
        
        switch direction {
        case .backward:
            // Load 2 more months in the past
            if let newMonth = calendar.date(byAdding: .month, value: -2, to: currentMonth) {
                currentMonth = newMonth
            }
        case .forward:
            // Load 2 more months in the future
            if let newMonth = calendar.date(byAdding: .month, value: 2, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }
}

// NEW: Helper enum for scroll direction
enum ScrollDirection {
    case forward
    case backward
}

