//
//  CleaningStatusDot.swift
//  BnBFox
//
//  Created on 12/16/2025.
//

import SwiftUI

struct CleaningStatusDot: View {
    let propertyName: String
    let propertyId: UUID
    let date: Date  // The date we're checking for
    let allBookings: [Booking]
    
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @State private var refreshID = UUID()
    
    // Cache the current gap (the one containing TODAY)
    private var currentGapInfo: GapInfo? {
        CleaningGapCache.shared.getCurrentGapInfo(propertyId: propertyId, bookings: allBookings)
    }
    
    var body: some View {
        Group {
            // Only show dot if this date is in the CURRENT gap (containing today)
            if let gap = currentGapInfo {
                let calendar = Calendar.current
                let dayStart = calendar.startOfDay(for: date)
                let now = calendar.startOfDay(for: Date())
                
                // Only show dot if:
                // 1. This date is in the gap range (checkout to check-in)
                // 2. Today is on or before the check-in day (show history until check-in)
                // 3. This date is not during an active booking
                // 4. This date is not in the future
                if dayStart >= gap.gapStart && dayStart <= gap.gapEnd && now <= gap.gapEnd && dayStart <= now {
                    if !isDuringActiveBooking(date: dayStart) {
                        // Use status from the checkout date for ALL days in the gap
                        if let status = statusManager.getStatus(propertyName: propertyName, date: gap.checkoutDate) {
                            PulsingDot(color: statusColor(status.status), isPulsing: status.status == .inProgress)
                        } else {
                            // Default to red (dirty/todo) if no status set yet
                            PulsingDot(color: .red, isPulsing: false)
                        }
                    }
                }
            }
        }
        .id(refreshID)
        .onAppear {
            // Refresh when dot appears (e.g., switching to calendar tab)
            print("👁️ CleaningStatusDot appeared for \(propertyName) on \(date)")
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CleaningStatusChanged"))) { _ in
            // Force view to refresh when cleaning status changes
            print("🔵 CleaningStatusDot received notification for \(propertyName) on \(date)")
            refreshID = UUID()
        }
    }
    
    private func isDuringActiveBooking(date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        let propertyBookings = allBookings.filter { $0.propertyId == propertyId }
        
        for booking in propertyBookings {
            let bookingStart = calendar.startOfDay(for: booking.startDate)
            let bookingEnd = calendar.startOfDay(for: booking.endDate)
            // Check if this day is DURING a booking (day AFTER checkin through day before checkout)
            if dayStart > bookingStart && dayStart < bookingEnd {
                return true
            }
        }
        return false
    }
    
    private func statusColor(_ status: CleaningStatus.Status) -> Color {
        switch status {
        case .pending:
            return .gray
        case .todo:
            return .red
        case .inProgress:
            return .orange  // Yellow/amber
        case .done:
            return .green
        }
    }
}

// Pulsing dot view for in-progress status
struct PulsingDot: View {
    let color: Color
    let isPulsing: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(isPulsing ? scale : 1.0)
            .onAppear {
                if isPulsing {
                    withAnimation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        scale = 1.5
                    }
                }
            }
    }
}

// Cache structure to avoid recalculating gaps for every dot
struct GapInfo {
    let checkoutDate: Date
    let gapStart: Date
    let gapEnd: Date
}

class CleaningGapCache {
    static let shared = CleaningGapCache()
    
    private var currentGapCache: [String: GapInfo?] = [:]
    private var lastBookingsHash: [String: Int] = [:]
    
    private init() {}
    
    // Get the CURRENT gap (the one containing TODAY) for a property
    func getCurrentGapInfo(propertyId: UUID, bookings: [Booking]) -> GapInfo? {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let cacheKey = propertyId.uuidString
        
        // Get property bookings
        let propertyBookings = bookings
            .filter { $0.propertyId == propertyId }
            .sorted { $0.endDate < $1.endDate }
        
        // Check if bookings changed - if so, invalidate cache for this property
        let bookingsHash = propertyBookings.map { "\($0.id)" }.joined().hashValue
        if lastBookingsHash[cacheKey] != bookingsHash {
            currentGapCache[cacheKey] = nil
            lastBookingsHash[cacheKey] = bookingsHash
        }
        
        // Check cache first
        if let cached = currentGapCache[cacheKey] {
            return cached
        }
        
        // Find the gap that contains TODAY
        for i in 0..<propertyBookings.count {
            let checkoutDate = calendar.startOfDay(for: propertyBookings[i].endDate)
            
            // Find next checkin after this checkout (including same-day turnovers)
            var nextCheckin: Date?
            for j in 0..<propertyBookings.count {
                let checkinDate = calendar.startOfDay(for: propertyBookings[j].startDate)
                if checkinDate >= checkoutDate {
                    if nextCheckin == nil || checkinDate < nextCheckin! {
                        nextCheckin = checkinDate
                    }
                }
            }
            
            // Calculate gap range
            let gapStart = checkoutDate
            let gapEnd: Date
            
            if let checkin = nextCheckin {
                // Gap extends through checkin day until next morning
                gapEnd = checkin
            } else {
                // No next booking - gap extends 7 days
                gapEnd = calendar.date(byAdding: .day, value: 7, to: checkoutDate) ?? checkoutDate
            }
            
            // Check if TODAY falls in this gap
            if now >= gapStart && now <= gapEnd {
                let gapInfo = GapInfo(checkoutDate: checkoutDate, gapStart: gapStart, gapEnd: gapEnd)
                currentGapCache[cacheKey] = gapInfo
                return gapInfo
            }
        }
        
        // No current gap found
        currentGapCache[cacheKey] = nil
        return nil
    }
    
    // Call this when bookings are refreshed to clear cache
    func invalidateCache() {
        currentGapCache.removeAll()
        lastBookingsHash.removeAll()
    }
}


