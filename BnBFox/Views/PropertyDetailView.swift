//
//  PropertyDetailView.swift
//  BnBShift
//
//  Created on 12/11/2025.
//

import SwiftUI

struct PropertyDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var propertyService: PropertyService
    @ObservedObject var statusManager = CleaningStatusManager.shared
    let property: Property
    
    @State private var currentProperty: Property
    @State private var allBookings: [Booking] = []
    @State private var currentMonthOffset: Int = 0
    @State private var refreshTrigger = false
    
    @State private var isEditingName = false
    @State private var editedDisplayName = ""
    
    @State private var isEditingAddress = false
    @State private var editedStreetAddress = ""
    @State private var editedUnit = ""
    @State private var editedCity = ""
    @State private var editedState = ""
    @State private var editedZipCode = ""
    
    @State private var isEditingOwner = false
    @State private var editedOwnerName = ""
    @State private var editedOwnerPhone = ""
    @State private var editedOwnerEmail = ""
    
    @State private var isEditingAccess = false
    @State private var editedDoorCode = ""
    @State private var editedBikeLocks = ""
    @State private var editedCamera = ""
    @State private var editedThermostat = ""
    @State private var editedOther = ""
    
    @State private var isEditingListings = false
    @State private var editedAirbnbURL = ""
    @State private var editedVrboURL = ""
    @State private var editedBookingComURL = ""
    
    @State private var isEditingNotes = false
    @State private var editedNotes = ""
    
    @State private var showingAdminPanel = false
    
    // Photo picker states
    @State private var showingImagePicker = false
    @State private var showingPhotoSourceSheet = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var showingDeletePhotoConfirmation = false
    
    init(property: Property) {
        self.property = property
        self._currentProperty = State(initialValue: property)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // HEADER: Property Name + Map Pin + Address
                    headerSection
                    
                    // CALENDAR: Compact version with shorter rows
                    calendarSection
                    
                    // PROPERTY PHOTO
                    propertyPhotoSection
                    
                    // ACCESS CODES & INFO
                    accessSection
                    
                    // OWNER INFORMATION
                    ownerSection
                    
                    // LISTING URLS
                    listingsSection
                    
                    // ICAL SOURCES
                    icalSourcesSection
                    
                    // NOTES
                    notesSection
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(todayStatusIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(todayStatusText)
                            .font(.system(size: 11))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                            .fixedSize()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(cleaningStatusIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .modifier(BlinkingModifier(shouldBlink: cleaningStatusIcon == "red-cleaning-button"))
                        Text(cleaningStatusText)
                            .font(.system(size: 11))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                            .fixedSize()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadBookings()
        }
        .onChange(of: property) { newProperty in
            currentProperty = newProperty
        }
        .sheet(isPresented: $showingAdminPanel) {
            AdminPanelView()
                .environmentObject(propertyService)
        }
    }
    
    // MARK: - Load Bookings
    
    private func loadBookings() async {
        allBookings = await BookingService.shared.fetchAllBookings(for: currentProperty)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Property Name with Lock/Unlock
            HStack {
                if isEditingName {
                    TextField("Property Name", text: $editedDisplayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentProperty.color)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(currentProperty.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentProperty.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    if isEditingName {
                        saveNameChanges()
                    } else {
                        startEditingName()
                    }
                }) {
                    Image(systemName: isEditingName ? "lock.open.fill" : "lock.fill")
                        .font(.title3)
                        .foregroundColor(isEditingName ? .green : .gray)
                }
            }
            
            Divider()
            
            // Compact Map Pin + Address Layout
            HStack(alignment: .top, spacing: 12) {
                // Map pin with label on left
                VStack(spacing: 2) {
                    Button(action: {
                        if let mapsURL = currentProperty.mapsURL {
                            UIApplication.shared.open(mapsURL)
                        }
                    }) {
                        Image("map-pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    .disabled(currentProperty.fullAddress.isEmpty)
                    .opacity(currentProperty.fullAddress.isEmpty ? 0.4 : 1.0)
                    
                    Text("Map")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Address on right
                if isEditingAddress {
                    VStack(spacing: 6) {
                        TextField("Street Address", text: $editedStreetAddress).textFieldStyle(RoundedBorderTextFieldStyle()).font(.caption)
                        TextField("Unit", text: $editedUnit).textFieldStyle(RoundedBorderTextFieldStyle()).font(.caption)
                        HStack(spacing: 6) {
                            TextField("City", text: $editedCity).textFieldStyle(RoundedBorderTextFieldStyle()).font(.caption)
                            TextField("State", text: $editedState).textFieldStyle(RoundedBorderTextFieldStyle()).font(.caption).frame(width: 60)
                            TextField("ZIP", text: $editedZipCode).textFieldStyle(RoundedBorderTextFieldStyle()).font(.caption).frame(width: 80)
                        }
                    }
                } else {
                    if currentProperty.fullAddress.isEmpty {
                        // Show instruction text when address is empty
                        Text("Click lock to set property address →")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Show actual address when set
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentProperty.streetAddress)
                                .font(.subheadline)
                            if !currentProperty.unit.isEmpty {
                                Text(currentProperty.unit).font(.subheadline)
                            }
                            if !currentProperty.city.isEmpty || !currentProperty.state.isEmpty || !currentProperty.zipCode.isEmpty {
                                Text("\(currentProperty.city), \(currentProperty.state) \(currentProperty.zipCode)").font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Lock button on far right
                Button(action: {
                    if isEditingAddress {
                        saveAddressChanges()
                    } else {
                        startEditingAddress()
                    }
                }) {
                    Image(systemName: isEditingAddress ? "lock.open.fill" : "lock.fill")
                        .font(.title3)
                        .foregroundColor(isEditingAddress ? .green : .gray)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    currentMonthOffset -= 1
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString(for: currentMonthOffset))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    currentMonthOffset += 1
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if let month = getMonth(offset: currentMonthOffset) {
                CompactSinglePropertyMonthView(
                    month: month,
                    bookings: allBookings,
                    property: currentProperty
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    // MARK: - Property Photo Section
    
    private var propertyPhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photo of front of property (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                
                Spacer()
                
                Button(action: {
                    showingPhotoSourceSheet = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                }
            }
            
            if let photoData = currentProperty.frontPhotoData,
               let uiImage = UIImage(data: photoData) {
                // Display existing photo
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                    
                    // Delete button
                    Button(action: {
                        showingDeletePhotoConfirmation = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                    }
                    .padding(8)
                }
            } else {
                // Placeholder when no photo
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No photo added")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .confirmationDialog("Choose Photo Source", isPresented: $showingPhotoSourceSheet) {
            Button("Take Photo") {
                photoSourceType = .camera
                showingImagePicker = true
            }
            Button("Choose from Library") {
                photoSourceType = .photoLibrary
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: photoSourceType)
                .onDisappear {
                    if let image = selectedImage {
                        savePhoto(image)
                    }
                }
        }
        .alert("Delete Photo?", isPresented: $showingDeletePhotoConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text("Are you sure you want to delete this property photo? This action cannot be undone.")
        }
    }
    
    // MARK: - Access Section
    
    private var accessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Access Codes & Info")
                    .font(.headline)
                Spacer()
                Button(action: {
                    if isEditingAccess {
                        saveAccessChanges()
                    } else {
                        startEditingAccess()
                    }
                }) {
                    Image(systemName: isEditingAccess ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(isEditingAccess ? .green : .gray)
                }
            }
            
            if isEditingAccess {
                VStack(spacing: 8) {
                    TextField("Door Code", text: $editedDoorCode).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Bike Locks", text: $editedBikeLocks).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Camera", text: $editedCamera).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Thermostat", text: $editedThermostat).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Other", text: $editedOther).textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    infoRow(label: "Door Code", value: currentProperty.doorCode)
                    infoRow(label: "Bike Locks", value: currentProperty.bikeLocks)
                    infoRow(label: "Camera", value: currentProperty.camera)
                    infoRow(label: "Thermostat", value: currentProperty.thermostat)
                    infoRow(label: "Other", value: currentProperty.other)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    // MARK: - Owner Section
    
    private var ownerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Owner Information")
                    .font(.headline)
                Spacer()
                Button(action: {
                    if isEditingOwner {
                        saveOwnerChanges()
                    } else {
                        startEditingOwner()
                    }
                }) {
                    Image(systemName: isEditingOwner ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(isEditingOwner ? .green : .gray)
                }
            }
            
            if isEditingOwner {
                VStack(spacing: 8) {
                    TextField("Owner Name", text: $editedOwnerName).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Phone", text: $editedOwnerPhone).textFieldStyle(RoundedBorderTextFieldStyle()).keyboardType(.phonePad)
                    TextField("Email", text: $editedOwnerEmail).textFieldStyle(RoundedBorderTextFieldStyle()).keyboardType(.emailAddress).autocapitalization(.none)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    infoRow(label: "Name", value: currentProperty.ownerName)
                    HStack {
                        Text("Phone:").font(.subheadline).foregroundColor(.secondary)
                        if currentProperty.ownerPhone.isEmpty {
                            Text("Not set").font(.subheadline).foregroundColor(.secondary)
                        } else {
                            Link(currentProperty.ownerPhone, destination: URL(string: "tel:\(currentProperty.ownerPhone)")!).font(.subheadline)
                        }
                        Spacer()
                    }
                    HStack {
                        Text("Email:").font(.subheadline).foregroundColor(.secondary)
                        if currentProperty.ownerEmail.isEmpty {
                            Text("Not set").font(.subheadline).foregroundColor(.secondary)
                        } else {
                            Link(currentProperty.ownerEmail, destination: URL(string: "mailto:\(currentProperty.ownerEmail)")!).font(.subheadline)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    private var listingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Listing URLs")
                    .font(.headline)
                Spacer()
                Button(action: {
                    if isEditingListings {
                        saveListingsChanges()
                    } else {
                        startEditingListings()
                    }
                }) {
                    Image(systemName: isEditingListings ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(isEditingListings ? .green : .gray)
                }
            }
            
            if isEditingListings {
                VStack(spacing: 8) {
                    TextField("Airbnb URL", text: $editedAirbnbURL).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
                    TextField("VRBO URL", text: $editedVrboURL).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
                    TextField("Booking.com URL", text: $editedBookingComURL).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    linkRow(label: "Airbnb", url: currentProperty.airbnbListingURL)
                    linkRow(label: "VRBO", url: currentProperty.vrboListingURL)
                    linkRow(label: "Booking.com", url: currentProperty.bookingComListingURL)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    private var icalSourcesSection: some View {
        Button(action: {
            showingAdminPanel = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("iCal Sources")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                Text("Tap to manage iCal sources")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(currentProperty.sources) { source in
                        HStack {
                            Image(systemName: platformIcon(source.platform))
                                .foregroundColor(currentProperty.color)
                            Text(source.platform.rawValue.capitalized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    if currentProperty.sources.isEmpty {
                        Text("No calendar sources connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Button(action: {
                    if isEditingNotes {
                        saveNotesChanges()
                    } else {
                        startEditingNotes()
                    }
                }) {
                    Image(systemName: isEditingNotes ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(isEditingNotes ? .green : .gray)
                }
            }
            
            if isEditingNotes {
                TextEditor(text: $editedNotes)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            } else {
                Text(currentProperty.notes.isEmpty ? "No notes" : currentProperty.notes)
                    .font(.body)
                    .foregroundColor(currentProperty.notes.isEmpty ? .secondary : .primary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    // MARK: - Status Logic
    
    private var todayStatusIcon: String {
        let today = Calendar.current.startOfDay(for: Date())
        let hasCheckout = allBookings.contains { Calendar.current.isDate($0.endDate, inSameDayAs: today) }
        let hasCheckin = allBookings.contains { Calendar.current.isDate($0.startDate, inSameDayAs: today) }
        
        if hasCheckout && hasCheckin {
            return "checkout-checkin"
        } else if hasCheckout {
            return "checkout"
        } else if hasCheckin {
            return "checkin"
        } else {
            // Check if occupied or vacant
            let isOccupied = allBookings.contains { booking in
                booking.startDate <= today && booking.endDate >= today
            }
            return isOccupied ? "occupied" : "vacant"
        }
    }
    
    private var todayStatusText: String {
        let today = Calendar.current.startOfDay(for: Date())
        let hasCheckout = allBookings.contains { Calendar.current.isDate($0.endDate, inSameDayAs: today) }
        let hasCheckin = allBookings.contains { Calendar.current.isDate($0.startDate, inSameDayAs: today) }
        
        if hasCheckout && hasCheckin {
            return "Check-out\nCheck-in"
        } else if hasCheckout {
            return "Check-out"
        } else if hasCheckin {
            return "Check-in"
        } else {
            let isOccupied = allBookings.contains { booking in
                booking.startDate <= today && booking.endDate >= today
            }
            return isOccupied ? "Occupied" : "Vacant"
        }
    }
    
    private var cleaningStatusIcon: String {
        let today = Calendar.current.startOfDay(for: Date())
        let hasCheckout = allBookings.contains { Calendar.current.isDate($0.endDate, inSameDayAs: today) }
        let isOccupied = allBookings.contains { booking in
            booking.startDate <= today && booking.endDate >= today
        }
        
        // If occupied and no checkout today, show gray icon
        if isOccupied && !hasCheckout {
            return "grey-cleaning-button"
        }
        
        // Get cleaning status from CleaningStatusManager
        if let status = statusManager.getStatus(propertyName: currentProperty.displayName, date: today) {
            switch status.status {
            case .done:
                return "green-cleaning-button"
            case .inProgress:
                return "amber-cleaning-button"
            case .todo, .pending:
                return "red-cleaning-button"
            }
        }
        
        // Default to red if no status found and there's a checkout
        return hasCheckout ? "red-cleaning-button" : "grey-cleaning-button"
    }
    
    private var cleaningStatusText: String {
        let today = Calendar.current.startOfDay(for: Date())
        let hasCheckout = allBookings.contains { Calendar.current.isDate($0.endDate, inSameDayAs: today) }
        let isOccupied = allBookings.contains { booking in
            booking.startDate <= today && booking.endDate >= today
        }
        
        if isOccupied && !hasCheckout {
            return "No Cleaning\nNecessary"
        }
        
        // Get cleaning status from CleaningStatusManager
        if let status = statusManager.getStatus(propertyName: currentProperty.displayName, date: today) {
            switch status.status {
            case .done:
                return "Clean"
            case .inProgress:
                return "Cleaning"
            case .todo, .pending:
                return "Dirty"
            }
        }
        
        // Default to Dirty if no status found and there's a checkout
        return hasCheckout ? "Dirty" : "No Cleaning\nNecessary"
    }
    
    // MARK: - Helpers
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":").font(.subheadline).foregroundColor(.secondary)
            Text(value.isEmpty ? "Not set" : value).font(.subheadline).foregroundColor(value.isEmpty ? .secondary : .primary)
            Spacer()
        }
    }
    
    private func linkRow(label: String, url: String) -> some View {
        HStack {
            Text(label + ":").font(.subheadline).foregroundColor(.secondary)
            if url.isEmpty {
                Text("Not set").font(.subheadline).foregroundColor(.secondary)
            } else {
                Link(url, destination: URL(string: url) ?? URL(string: "https://")!).font(.subheadline).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
        }
    }
    
    private func platformIcon(_ platform: Platform) -> String {
        switch platform {
        case .airbnb: return "house.fill"
        case .vrbo: return "building.2.fill"
        case .bookingCom: return "bed.double.fill"
        }
    }
    
    private func getMonth(offset: Int) -> Date? {
        Calendar.current.date(byAdding: .month, value: offset, to: Date())
    }
    
    private func monthYearString(for offset: Int) -> String {
        guard let date = getMonth(offset: offset) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Save Methods
    
    private func startEditingName() {
        editedDisplayName = currentProperty.displayName
        isEditingName = true
    }
    
    private func saveNameChanges() {
        var updated = currentProperty
        updated.displayName = editedDisplayName
        currentProperty = updated
        propertyService.updateProperty(updated)
        isEditingName = false
    }
    
    private func savePhoto(_ image: UIImage) {
        // Compress image to reasonable size
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        
        var updated = currentProperty
        updated.frontPhotoData = imageData
        currentProperty = updated
        propertyService.updateProperty(updated)
        selectedImage = nil
    }
    
    private func deletePhoto() {
        var updated = currentProperty
        updated.frontPhotoData = nil
        currentProperty = updated
        propertyService.updateProperty(updated)
    }
    
    private func startEditingAddress() {
        editedStreetAddress = currentProperty.streetAddress
        editedUnit = currentProperty.unit
        editedCity = currentProperty.city
        editedState = currentProperty.state
        editedZipCode = currentProperty.zipCode
        isEditingAddress = true
    }
    
    private func saveAddressChanges() {
        var updated = currentProperty
        updated.streetAddress = editedStreetAddress
        updated.unit = editedUnit
        updated.city = editedCity
        updated.state = editedState
        updated.zipCode = editedZipCode
        currentProperty = updated
        propertyService.updateProperty(updated)
        isEditingAddress = false
    }
    
    private func startEditingOwner() {
        editedOwnerName = currentProperty.ownerName
        editedOwnerPhone = currentProperty.ownerPhone
        editedOwnerEmail = currentProperty.ownerEmail
        isEditingOwner = true
    }
    
    private func saveOwnerChanges() {
        var updated = currentProperty
        updated.ownerName = editedOwnerName
        updated.ownerPhone = editedOwnerPhone
        updated.ownerEmail = editedOwnerEmail
        currentProperty = updated
        propertyService.updateProperty(updated)
        isEditingOwner = false
    }
    
    private func startEditingAccess() {
        editedDoorCode = currentProperty.doorCode
        editedBikeLocks = currentProperty.bikeLocks
        editedCamera = currentProperty.camera
        editedThermostat = currentProperty.thermostat
        editedOther = currentProperty.other
        isEditingAccess = true
    }
    
    private func saveAccessChanges() {
        var updated = currentProperty
        updated.doorCode = editedDoorCode
        updated.bikeLocks = editedBikeLocks
        updated.camera = editedCamera
        updated.thermostat = editedThermostat
        updated.other = editedOther
        currentProperty = updated
        propertyService.updateProperty(updated)
        isEditingAccess = false
    }
    
    private func startEditingListings() {
        editedAirbnbURL = currentProperty.airbnbListingURL
        editedVrboURL = currentProperty.vrboListingURL
        editedBookingComURL = currentProperty.bookingComListingURL
        isEditingListings = true
    }
    
    private func saveListingsChanges() {
        var updated = currentProperty
        updated.airbnbListingURL = editedAirbnbURL
        updated.vrboListingURL = editedVrboURL
        updated.bookingComListingURL = editedBookingComURL
        currentProperty = updated
        propertyService.updateProperty(updated)
        isEditingListings = false
    }
    
    private func startEditingNotes() {
        editedNotes = currentProperty.notes
        isEditingNotes = true
    }
    
    private func saveNotesChanges() {
        var updated = currentProperty
        updated.notes = editedNotes
        currentProperty = updated
        propertyService.updateProperty(updated)
        isEditingNotes = false
    }
}

// MARK: - Compact Month View

struct CompactSinglePropertyMonthView: View {
    let month: Date
    let bookings: [Booking]
    let property: Property
    
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 13, weight: index == 0 ? .regular : .bold))
                        .foregroundColor(index == 0 ? .red : .black)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Calendar weeks
            ForEach(Array(generateWeeks().enumerated()), id: \.offset) { weekIndex, week in
                CompactSinglePropertyWeekSection(
                    week: week,
                    bookings: bookings,
                    currentMonth: month,
                    property: property
                )
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func generateWeeks() -> [[Date?]] {
        let calendar = Calendar.current
        let startOfMonth = month.startOfMonth()
        let firstWeekday = month.firstWeekdayOfMonth()
        let daysInMonth = month.daysInMonth()
        
        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        
        // Previous month days
        if firstWeekday > 1 {
            let daysToAdd = firstWeekday - 1
            for dayOffset in (1...daysToAdd).reversed() {
                if let prevDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfMonth) {
                    currentWeek.append(prevDate)
                }
            }
        }
        
        // Current month days
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                currentWeek.append(date)
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }
        
        // Next month days
        if currentWeek.count > 0 && currentWeek.count < 7 {
            let lastDayOfMonth = calendar.date(byAdding: .day, value: daysInMonth - 1, to: startOfMonth)!
            var dayOffset = 1
            while currentWeek.count < 7 {
                if let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: lastDayOfMonth) {
                    currentWeek.append(nextDate)
                    dayOffset += 1
                }
            }
        }
        
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }
        
        return weeks
    }
}

struct CompactSinglePropertyWeekSection: View {
    let week: [Date?]
    let bookings: [Booking]
    let currentMonth: Date
    let property: Property
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background grid
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    let hasCheckout = date != nil ? dateHasCheckout(date!) : false
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(
                            hasCheckout ? Color.green.opacity(0.15) :
                            (isInCurrentMonth(date) ? Color.white : Color.gray.opacity(0.05))
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 60)
            
            VStack(alignment: .leading, spacing: 0) {
                // Day numbers - positioned at TOP
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                        ZStack {
                            if let date = date {
                                Text("\(date.dayNumber())")
                                    .font(.system(size: 15))
                                    .fontWeight(date.isToday() ? .bold : .regular)
                                    .foregroundColor(
                                        date.isToday() ? .white :
                                        (isInCurrentMonth(date) ? .primary : .gray.opacity(0.5))
                                    )
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle().fill(date.isToday() ? Color.blue : Color.clear)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(height: 28)
                .padding(.top, 2)
                
                Spacer()
                
                // Booking bars - positioned BELOW day numbers
                GeometryReader { geometry in
                    let totalWidth = geometry.size.width
                    let cellWidth = totalWidth / 7
                    
                    ZStack(alignment: .leading) {
                        ForEach(bookings, id: \.id) { booking in
                            CompactBookingBar(
                                booking: booking,
                                property: property,
                                week: week,
                                cellWidth: cellWidth,
                                currentMonth: currentMonth
                            )
                        }
                    }
                }
                .frame(height: 24)
                .padding(.bottom, 4)
            }
            .frame(height: 60)
        }
    }
    
    private func dateHasCheckout(_ date: Date) -> Bool {
        let dayStart = Calendar.current.startOfDay(for: date)
        return bookings.contains { booking in
            Calendar.current.isDate(booking.endDate, inSameDayAs: dayStart)
        }
    }
    
    private func isInCurrentMonth(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
}

// MARK: - Compact Booking Bar

struct CompactBookingBar: View {
    let booking: Booking
    let property: Property
    let week: [Date?]
    let cellWidth: CGFloat
    let currentMonth: Date
    
    var body: some View {
        let barGeometry = calculateBarGeometry()
        
        if barGeometry.width > 0 {
            HStack(spacing: 0) {
                ForEach(Array(barGeometry.segments.enumerated()), id: \.offset) { index, segment in
                    Rectangle()
                        .fill(segment.isInCurrentMonth ? property.color : Color.gray.opacity(0.4))
                        .frame(width: segment.width)
                }
            }
            .frame(height: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: barGeometry.isActualStart ? 4 : 0,
                    bottomLeadingRadius: barGeometry.isActualStart ? 4 : 0,
                    bottomTrailingRadius: barGeometry.isActualEnd ? 4 : 0,
                    topTrailingRadius: barGeometry.isActualEnd ? 4 : 0
                )
            )
            .overlay(
                Text(property.shortName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .padding(.leading, 4),
                alignment: .leading
            )
            .offset(x: barGeometry.xOffset)
        }
    }
    
    private func calculateBarGeometry() -> (xOffset: CGFloat, width: CGFloat, segments: [(width: CGFloat, isInCurrentMonth: Bool)], isActualStart: Bool, isActualEnd: Bool) {
        let calendar = Calendar.current
        guard let firstDate = week.compactMap({ $0 }).first,
              let lastDate = week.compactMap({ $0 }).last else {
            return (0, 0, [], false, false)
        }
        
        let bookingStart = calendar.startOfDay(for: booking.startDate)
        let bookingEnd = calendar.startOfDay(for: booking.endDate)
        let weekStart = calendar.startOfDay(for: firstDate)
        let weekEnd = calendar.startOfDay(for: lastDate)
        
        guard bookingStart <= weekEnd && bookingEnd >= weekStart else {
            return (0, 0, [], false, false)
        }
        
        let displayStart = max(bookingStart, weekStart)
        let displayEnd = min(bookingEnd, weekEnd)
        
        var startDayIndex = 0
        var endDayIndex = 6
        var isCheckInDay = false
        var isCheckOutDay = false
        
        for (index, date) in week.enumerated() {
            guard let date = date else { continue }
            let dayStart = calendar.startOfDay(for: date)
            
            if calendar.isDate(dayStart, inSameDayAs: displayStart) {
                startDayIndex = index
                isCheckInDay = calendar.isDate(dayStart, inSameDayAs: bookingStart)
            }
            if calendar.isDate(dayStart, inSameDayAs: displayEnd) {
                endDayIndex = index
                isCheckOutDay = calendar.isDate(dayStart, inSameDayAs: bookingEnd)
            }
        }
        
        var xOffset = CGFloat(startDayIndex) * cellWidth
        var totalWidth = CGFloat(endDayIndex - startDayIndex + 1) * cellWidth
        
        if isCheckInDay {
            xOffset += cellWidth / 2
            totalWidth -= cellWidth / 2
        }
        
        if isCheckOutDay {
            totalWidth -= cellWidth / 2
        }
        
        var segments: [(width: CGFloat, isInCurrentMonth: Bool)] = []
        for i in startDayIndex...endDayIndex {
            if let date = week[i] {
                let isInMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                var segmentWidth = cellWidth
                
                if i == startDayIndex && isCheckInDay {
                    segmentWidth = cellWidth / 2
                } else if i == endDayIndex && isCheckOutDay {
                    segmentWidth = cellWidth / 2
                }
                
                segments.append((segmentWidth, isInMonth))
            }
        }
        
        return (xOffset, totalWidth, segments, isCheckInDay, isCheckOutDay)
    }
}

// MARK: - Blinking Modifier for Red Cleaning Bottle

struct BlinkingModifier: ViewModifier {
    let shouldBlink: Bool
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .opacity(shouldBlink ? opacity : 1.0)
            .onAppear {
                if shouldBlink {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        opacity = 0.3
                    }
                }
            }
    }
}


