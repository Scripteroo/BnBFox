//
//  ICalService.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation

class ICalService {
    static let shared = ICalService()
    
    private init() {}
    
    func fetchICalData(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let icalString = String(data: data, encoding: .utf8) else {
            throw ICalError.invalidEncoding
        }
        return icalString
    }
    
    func parseICalData(_ icalString: String, platform: Platform, propertyId: UUID) -> [Booking] {
        var bookings: [Booking] = []
        let events = extractEvents(from: icalString)
        
        print("📅 Parsing \(events.count) events from \(platform.displayName) iCal data")
        
        var skippedCount = 0
        for event in events {
            guard let startDate = parseDate(event["DTSTART"]),
                  let endDate = parseDate(event["DTEND"]),
                  let uid = event["UID"] else {
                skippedCount += 1
                if skippedCount <= 3 { // Log first 3 skipped events for debugging
                    print("⚠️ Skipping event - missing required fields. DTSTART: \(event["DTSTART"] ?? "nil"), DTEND: \(event["DTEND"] ?? "nil"), UID: \(event["UID"] ?? "nil")")
                }
                continue
            }
            
            let guestName = extractGuestName(from: event["SUMMARY"], platform: platform)
            
            let booking = Booking(
                id: uid,
                startDate: startDate,
                endDate: endDate,
                guestName: guestName,
                platform: platform,
                propertyId: propertyId
            )
            
            bookings.append(booking)
        }
        
        if skippedCount > 0 {
            print("⚠️ Skipped \(skippedCount) events due to missing required fields")
        }
        
        print("✅ Parsed \(bookings.count) valid bookings from \(platform.displayName)")
        return bookings
    }
    
    private func extractEvents(from icalString: String) -> [[String: String]] {
        var events: [[String: String]] = []
        var currentEvent: [String: String] = [:]
        var inEvent = false
        var currentKey: String?
        var currentValue = ""
        
        let lines = icalString.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
                continue
            }
            
            if trimmedLine == "END:VEVENT" {
                if let key = currentKey {
                    currentEvent[key] = currentValue.trimmingCharacters(in: .whitespaces)
                }
                events.append(currentEvent)
                inEvent = false
                currentKey = nil
                currentValue = ""
                continue
            }
            
            if inEvent {
                // Handle line continuation (lines starting with space or tab)
                if trimmedLine.first == " " || trimmedLine.first == "\t" {
                    currentValue += trimmedLine.trimmingCharacters(in: .whitespaces)
                    continue
                }
                
                // Save previous key-value pair
                if let key = currentKey {
                    currentEvent[key] = currentValue.trimmingCharacters(in: .whitespaces)
                }
                
                // Parse new key-value pair
                if let colonIndex = trimmedLine.firstIndex(of: ":") {
                    let keyPart = String(trimmedLine[..<colonIndex])
                    let valuePart = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
                    
                    // Extract the actual key (before semicolon if present)
                    if let semicolonIndex = keyPart.firstIndex(of: ";") {
                        currentKey = String(keyPart[..<semicolonIndex])
                    } else {
                        currentKey = keyPart
                    }
                    
                    currentValue = valuePart
                }
            }
        }
        
        return events
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Remove VALUE=DATE: prefix if present
        let cleanDateString = dateString.replacingOccurrences(of: "VALUE=DATE:", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try YYYYMMDD format (DATE format - no time component)
        // For date-only values, use current timezone to avoid day shifts
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone.current
        if let date = dateFormatter.date(from: cleanDateString) {
            return date
        }
        
        // For datetime formats, use UTC
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        // Try YYYYMMDDTHHmmssZ format (DATETIME format)
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        if let date = dateFormatter.date(from: cleanDateString) {
            return date
        }
        
        // Try YYYYMMDDTHHmmss format (DATETIME without Z)
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        if let date = dateFormatter.date(from: cleanDateString) {
            return date
        }
        
        return nil
    }
    
    private func extractGuestName(from summary: String?, platform: Platform) -> String? {
        guard let summary = summary else { return nil }
        
        // VRBO format: "Reserved - GuestName"
        if platform == .vrbo {
            if let dashIndex = summary.firstIndex(of: "-") {
                let nameStartIndex = summary.index(after: dashIndex)
                let name = String(summary[nameStartIndex...]).trimmingCharacters(in: .whitespaces)
                return name.isEmpty ? nil : name
            }
        }
        
        // AirBnB typically just says "Reserved"
        if summary.lowercased() == "reserved" {
            return nil
        }
        
        // If it's not just "Reserved", return the summary as the guest name
        return summary
    }
}

enum ICalError: Error {
    case invalidEncoding
    case invalidFormat
    case networkError
}
