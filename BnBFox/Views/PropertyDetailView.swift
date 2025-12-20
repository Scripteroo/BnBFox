//
//  PropertyDetailView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct PropertyDetailView: View {
    let propertyId: UUID  // Changed: store ID instead of full property
    let bookings: [Booking]
    @Environment(\.dismiss) var dismiss
    @State private var isPropertyInfoLocked = true
    @State private var isOwnerInfoLocked = true
    @State private var isListingURLsLocked = true
    @State private var isColorLocked = true
    @EnvironmentObject var propertyService: PropertyService
    @State private var property: Property = Property(  // Default placeholder
        name: "",
        displayName: "",
        shortName: "",
        colorHex: "007AFF",
        sources: []
    )
    
    init(propertyId: UUID, bookings: [Booking]) {
        self.propertyId = propertyId
        self.bookings = bookings
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    // Color Picker Panel
                    colorPickerPanel
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        // Small delay to ensure save completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                // Load fresh property from service
                if let loadedProperty = propertyService.getProperty(by: propertyId) {
                    property = loadedProperty
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
                
                if isPropertyInfoLocked {
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
            HStack {
                Spacer()
                Text("Property Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    isPropertyInfoLocked.toggle()
                }) {
                    Image(systemName: isPropertyInfoLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isPropertyInfoLocked ? .red : .green)
                }
            }
            .padding(.top, 8)
            
            // Door code
            FormField(
                label: "Door code",
                text: $property.doorCode,
                isLocked: isPropertyInfoLocked,
                placeholder: "0800"
            )
            
            // Bike Locks
            FormField(
                label: "Bike Locks",
                text: $property.bikeLocks,
                isLocked: isPropertyInfoLocked,
                placeholder: "0800"
            )
            
            // Camera (NEW)
            FormField(
                label: "Camera",
                text: $property.camera,
                isLocked: isPropertyInfoLocked,
                placeholder: "Camera info"
            )
            
            // Thermostat (NEW)
            FormField(
                label: "Thermostat",
                text: $property.thermostat,
                isLocked: isPropertyInfoLocked,
                placeholder: "Thermostat info"
            )
            
            // Other (NEW)
            FormField(
                label: "Other",
                text: $property.other,
                isLocked: isPropertyInfoLocked,
                placeholder: "Other info"
            )
        }
        .padding()
        .background(Color.white)
        .padding(.top, 8)
    }
    
    private var ownerInfoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Text("Owner Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    isOwnerInfoLocked.toggle()
                }) {
                    Image(systemName: isOwnerInfoLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isOwnerInfoLocked ? .red : .green)
                }
            }
            .padding(.top, 8)
            
            // Owner
            FormField(
                label: "Owner",
                text: $property.ownerName,
                isLocked: isOwnerInfoLocked,
                placeholder: "Phil Goss"
            )
            
            // Phone
            FormField(
                label: "Phone",
                text: $property.ownerPhone,
                isLocked: isOwnerInfoLocked,
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
                isLocked: isOwnerInfoLocked,
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
            HStack {
                Spacer()
                Text("Listing URLs")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    isListingURLsLocked.toggle()
                }) {
                    Image(systemName: isListingURLsLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isListingURLsLocked ? .red : .green)
                }
            }
            .padding(.top, 8)
            
            // AirBnB Listing
            ListingURLField(
                label: "AirBnB",
                text: $property.airbnbListingURL,
                isLocked: isListingURLsLocked,
                placeholder: "https://www.airbnb.com/rooms/..."
            )
            
            // VRBO Listing
            ListingURLField(
                label: "VRBO",
                text: $property.vrboListingURL,
                isLocked: isListingURLsLocked,
                placeholder: "https://www.vrbo.com/..."
            )
            
            // Booking.com Listing
            ListingURLField(
                label: "Booking.com",
                text: $property.bookingComListingURL,
                isLocked: isListingURLsLocked,
                placeholder: "https://www.booking.com/..."
            )
        }
        .padding()
        .background(Color.white)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    private var colorPickerPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Text("Color")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    isColorLocked.toggle()
                }) {
                    Image(systemName: isColorLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isColorLocked ? .red : .green)
                }
            }
            .padding(.top, 8)
            
            HStack(spacing: 16) {
                // Color square with picker
                ColorPicker("", selection: Binding(
                    get: { property.color },
                    set: { newColor in
                        property.colorHex = newColor.toHex() ?? property.colorHex
                    }
                ))
                .labelsHidden()
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(property.color)
                )
                .disabled(isColorLocked)
                
                Spacer()
                
                // Live preview of occupancy bar
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(property.color)
                        .frame(height: 32)
                    
                    Text(property.shortName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.white)
        .padding(.top, 8)
        .padding(.bottom, 20)
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

// MARK: - Color Extension
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(format: "%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}


