//
//  DateExtensions.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: self.startOfMonth()),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            return self
        }
        return endOfMonth
    }
    
    func addMonths(_ months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
    
    func dayNumber() -> Int {
        return Calendar.current.component(.day, from: self)
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
    
    func daysInMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self)
        return range?.count ?? 30
    }
    
    func firstWeekdayOfMonth() -> Int {
        let calendar = Calendar.current
        let firstDay = self.startOfMonth()
        return calendar.component(.weekday, from: firstDay)
    }
    
    func getAllDaysInMonth() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = self.startOfMonth()
        let daysCount = self.daysInMonth()
        
        var dates: [Date] = []
        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                dates.append(date)
            }
        }
        return dates
    }
}

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}
