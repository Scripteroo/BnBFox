//
//  PropertyDetailView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct PropertyDetailView: View {
    @State var property: Property
    let bookings: [Booking]
    @Environment(\.dismiss) var dismiss
    @State private var isLocked = true
    @EnvironmentObject var propertyService: PropertyService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Calendar Section (MOVED TO TOP)
                    calendarSection
                    
                    // Property Information Panel
                    propertyInfoPanel
                    
                    // Owner Info Panel
                    ownerInfoPanel
                    
                    // Listing URLs Panel
                    listingURLsPanel
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
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar - \(property.shortName)")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Single property calendar
            SinglePropertyCalendarView(
                property: property,
                bookings: bookings.filter { $0.propertyId == property.id }
            )
            .frame(minHeight: 400)
            
            // Notes section below calendar
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                if isLocked {
                    Text(property.notes.isEmpty ? "No notes" : property.notes)
                        .font(.system(size: 14))
                        .foregroundColor(property.notes.isEmpty ? .gray : .primary)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                        .padding(.horizontal)
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
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }
    
    private var propertyInfoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Property Information")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            
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
            
            // Camera (NEW)
            FormField(
                label: "Camera",
                text: $property.camera,
                isLocked: isLocked,
                placeholder: "Camera info"
            )
            
            // Thermostat (NEW)
            FormField(
                label: "Thermostat",
                text: $property.thermostat,
                isLocked: isLocked,
                placeholder: "Thermostat info"
            )
            
            // Other (NEW)
            FormField(
                label: "Other",
                text: $property.other,
                isLocked: isLocked,
                placeholder: "Other info"
            )
        }
        .padding()
        .background(Color.white)
        .padding(.top, 8)
    }
    
    private var ownerInfoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Owner Information")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            
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
        }
        .padding()
        .background(Color.white)
        .padding(.top, 8)
    }
    
    private var listingURLsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Listing URLs")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            
            // AirBnB Listing
            ListingURLField(
                label: "AirBnB",
                text: $property.airbnbListingURL,
                isLocked: isLocked,
                placeholder: "https://www.airbnb.com/rooms/..."
            )
            
            // VRBO Listing
            ListingURLField(
                label: "VRBO",
                text: $property.vrboListingURL,
                isLocked: isLocked,
                placeholder: "https://www.vrbo.com/..."
            )
            
            // Booking.com Listing
            ListingURLField(
                label: "Booking.com",
                text: $property.bookingComListingURL,
                isLocked: isLocked,
                placeholder: "https://www.booking.com/..."
            )
        }
        .padding()
        .background(Color.white)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    private func saveChanges() {
        print("🔴 SAVE CALLED")
        print("🔴 Property ID: \(property.id)")
        print("🔴 Camera: '\(property.camera)'")
        print("🔴 Thermostat: '\(property.thermostat)'")
        print("🔴 Door code: '\(property.doorCode)'")
        print("🔴 AirBnB URL: '\(property.airbnbListingURL)'")
        
        propertyService.updateProperty(property)
        
        print("🔴 SAVE COMPLETED")
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
                .frame(width: 100, alignment: .leading)
            
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

// NEW - Listing URL Field with clickable link
struct ListingURLField: View {
    let label: String
    @Binding var text: String
    let isLocked: Bool
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 100, alignment: .leading)
            
            if isLocked {
                if !text.isEmpty, let url = URL(string: text) {
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        Text(text)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                            .underline()
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                } else {
                    Text(placeholder)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 12))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
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
                month: currentMonth,
                bookings: bookings,
                showMonthTitle: false,  // Hide duplicate title since we show it in navigation
                showDayHeaders: false   // Hide duplicate day headers since we show them above
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
