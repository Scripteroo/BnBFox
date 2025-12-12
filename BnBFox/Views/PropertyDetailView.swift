//
//  PropertyDetailView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct PropertyDetailView: View {
    @State var property: Property
    @Environment(\.dismiss) var dismiss
    @State private var isLocked = true
    @EnvironmentObject var propertyService: PropertyService
    @EnvironmentObject var bookingService: BookingService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Owner Info Panel
                    ownerInfoPanel
                    
                    // Calendar Section
                    calendarSection
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Kawama Maintenance")
                .font(.system(size: 18, weight: .semibold))
            Text("Owner Info Panel")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            HStack {
                Text(property.complexName)
                    .font(.system(size: 16))
                Text(property.shortName)
                    .font(.system(size: 16, weight: .bold))
            }
            
            HStack(spacing: 16) {
                // Lock/Unlock button
                Button(action: {
                    isLocked.toggle()
                }) {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isLocked ? .red : .gray)
                }
                
                // Edit button (visual only, editing controlled by lock)
                Image(systemName: "pencil")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var ownerInfoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Owner
            FormField(
                label: "Owner",
                text: $property.ownerName,
                isLocked: isLocked,
                placeholder: "Phil Goss"
            )
            
            // Phone
            FormField(
                label: "Phone",
                text: $property.ownerPhone,
                isLocked: isLocked,
                placeholder: "+1 (812) 589-1482",
                keyboardType: .phonePad,
                isLink: true,
                linkAction: {
                    if let url = URL(string: "tel://\(property.ownerPhone.filter { $0.isNumber })") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            
            // Email
            FormField(
                label: "email",
                text: $property.ownerEmail,
                isLocked: isLocked,
                placeholder: "email",
                keyboardType: .emailAddress,
                isLink: true,
                linkAction: {
                    if let url = URL(string: "mailto:\(property.ownerEmail)") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            
            Divider()
            
            // iCal URLs Section
            Text("iCal URL")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // AirBnB
            iCalField(
                label: "AirBnB",
                url: property.sources.first(where: { $0.platform == .airbnb })?.icalURL ?? "",
                isLocked: isLocked
            )
            
            // VRBO
            iCalField(
                label: "VRBO",
                url: property.sources.first(where: { $0.platform == .vrbo })?.icalURL ?? "",
                isLocked: isLocked
            )
            
            // Booking.com
            iCalField(
                label: "Booking.com",
                url: property.sources.first(where: { $0.platform == .bookingCom })?.icalURL ?? "",
                isLocked: isLocked
            )
            
            Divider()
            
            // Door code
            FormField(
                label: "Door code",
                text: $property.doorCode,
                isLocked: isLocked,
                placeholder: "0800"
            )
            
            // Bike Locks
            FormField(
                label: "Bike Locks",
                text: $property.bikeLocks,
                isLocked: isLocked,
                placeholder: "0800"
            )
            
            // Notes
            VStack(alignment: .leading, spacing: 4) {
                if isLocked {
                    Text(property.notes.isEmpty ? "Notes:" : property.notes)
                        .font(.system(size: 14))
                        .foregroundColor(property.notes.isEmpty ? .gray : .primary)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                } else {
                    TextEditor(text: $property.notes)
                        .font(.system(size: 14))
                        .frame(minHeight: 120)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar - \(property.shortName)")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Single property calendar will go here
            SinglePropertyCalendarView(
                property: property,
                bookings: bookingService.bookings.filter { $0.propertyId == property.id }
            )
            .frame(minHeight: 400)
        }
        .background(Color.white)
    }
    
    private func saveChanges() {
        // Save property changes to PropertyService
        propertyService.updateProperty(property)
    }
}

struct FormField: View {
    let label: String
    @Binding var text: String
    let isLocked: Bool
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isLink: Bool = false
    var linkAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 80, alignment: .leading)
            
            if isLocked {
                if isLink && !text.isEmpty {
                    Button(action: {
                        linkAction?()
                    }) {
                        Text(text.isEmpty ? placeholder : text)
                            .font(.system(size: 14))
                            .foregroundColor(text.isEmpty ? .gray : .blue)
                            .underline()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                } else {
                    Text(text.isEmpty ? placeholder : text)
                        .font(.system(size: 14))
                        .foregroundColor(text.isEmpty ? .gray : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .keyboardType(keyboardType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
}

struct iCalField: View {
    let label: String
    let url: String
    let isLocked: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 80, alignment: .leading)
            
            Text(url.isEmpty ? "\(label) iCal" : url)
                .font(.system(size: 12))
                .foregroundColor(url.isEmpty ? .gray : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(4)
        }
    }
}

// Single property calendar view
struct SinglePropertyCalendarView: View {
    let property: Property
    let bookings: [Booking]
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding()
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            MonthView(
                currentMonth: currentMonth,
                properties: [property],
                bookings: bookings
            )
            .padding(.horizontal, 8)
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}
