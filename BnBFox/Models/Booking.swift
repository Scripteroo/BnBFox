//
//  Booking.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation

struct Booking: Identifiable, Hashable {
    let id: String
    let startDate: Date
    let endDate: Date
    let guestName: String?
    let platform: Platform
    let propertyId: UUID
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var displayName: String {
        if let guestName = guestName, !guestName.isEmpty {
            return guestName
        }
        return platform.shortName
    }
    
    func overlapsDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)
        let bookingStart = calendar.startOfDay(for: startDate)
        let bookingEnd = calendar.startOfDay(for: endDate)
        
        return dateStart >= bookingStart && dateStart < bookingEnd
    }
    
    func isFirstDay(of date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(startDate, inSameDayAs: date)
    }
    
    func isLastDay(of date: Date) -> Bool {
        let calendar = Calendar.current
        let dayBeforeEnd = calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        return calendar.isDate(dayBeforeEnd, inSameDayAs: date)
    }
}
