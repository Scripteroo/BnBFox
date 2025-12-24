//
//  SettingsView.swift
//  BnBFox
//
//  Updated with notification debugging tools
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var taskService = PeriodicTaskService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var pendingAlertsCount = 0
    @State private var upcomingCleanings: [CleaningDay] = []
    @State private var notificationStatus = "Checking..."
    @State private var showingTestAlert = false
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            Form {
                // Notification Status Section
                Section(header: Text("Notification Status")) {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundColor(notificationStatus == "Authorized" ? .green : .red)
                    }
                    
                    if notificationStatus != "Authorized" {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings to Enable")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                    

                    Button(action: {
                        Task {
                            await listScheduledNotifications()
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Scheduled Notifications")
                            Spacer()
                            Image(systemName: "eye")
                        }
                    }
                }
                
                // Cleaning Alerts Section
                Section(header: Text("Cleaning Day Alerts")) {
                    Toggle("Enable Alerts", isOn: $settings.cleaningAlertsEnabled)
                        .onChange(of: settings.cleaningAlertsEnabled) { _ in
                            Task {
                                await updatePendingCount()
                            }
                        }
                    
                    Toggle("Alert Sound", isOn: $settings.alertSoundEnabled)
                        .disabled(!settings.cleaningAlertsEnabled)
                    
                    DatePicker(
                        "Alert Time",
                        selection: $settings.alertTime,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!settings.cleaningAlertsEnabled)
                    .onChange(of: settings.alertTime) { _ in
                        Task {
                            // Reschedule notifications when time changes
                            await updatePendingCount()
                        }
                    }
                    
                    if settings.cleaningAlertsEnabled {
                        HStack {
                            Text("Pending Alerts")
                            Spacer()
                            Text("\(pendingAlertsCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            Task {
                                await forceRescheduleNotifications()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reschedule All Notifications")
                            }
                        }
                    }
                }
                
                // New Booking Alerts Section
                Section(header: Text("New Booking Alerts")) {
                    Toggle("Enable New Booking Alerts", isOn: $settings.newBookingAlertsEnabled)
                    
                    if settings.newBookingAlertsEnabled {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Get notified when new bookings appear in the current month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Maintenance Tasks Section
                Section(header: Text("Maintenance Tasks")) {
                    // Add Custom Task Button
                    Button(action: {
                        showingAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Custom Task")
                            Spacer()
                        }
                    }
                    
                    // List of Custom Tasks
                    ForEach(taskService.tasks.filter { !$0.isDefault }) { task in
                        CustomTaskRow(task: task, onDelete: {
                            taskService.deleteTask(task)
                        }, onToggle: { enabled in
                            var updatedTask = task
                            updatedTask.isEnabled = enabled
                            taskService.updateTask(updatedTask)
                        })
                    }
                }
                
                // Upcoming Cleanings Section
                if settings.cleaningAlertsEnabled && !upcomingCleanings.isEmpty {
                    Section(header: Text("Upcoming Cleanings (Next 30 Days)")) {
                        ForEach(upcomingCleanings) { cleaning in
                            CleaningDayRow(cleaning: cleaning)
                        }
                    }
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await checkNotificationStatus()
                    await updatePendingCount()
                    loadUpcomingCleanings()
                }
            }
            .alert("Test Notification Sent", isPresented: $showingTestAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A test notification will appear in 5 seconds. Make sure the app is in the background to see it.")
            }
            .sheet(isPresented: $showingAddTask) {
                AddCustomTaskView()
            }
        }
    }
    
    private func checkNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized:
                notificationStatus = "Authorized"
            case .denied:
                notificationStatus = "Denied"
            case .notDetermined:
                notificationStatus = "Not Requested"
            case .provisional:
                notificationStatus = "Provisional"
            case .ephemeral:
                notificationStatus = "Ephemeral"
            @unknown default:
                notificationStatus = "Unknown"
            }
        }
    }
    
    private func sendTestNotification() async {
        await NotificationService.shared.sendTestNotification()
        await MainActor.run {
            showingTestAlert = true
        }
    }
    
    private func listScheduledNotifications() async {
        await NotificationService.shared.listPendingNotifications()
        // Output will be in Xcode console
    }
    
    private func forceRescheduleNotifications() async {
        print("🔄 Force rescheduling all notifications...")
        NotificationService.shared.scheduleCleaningAlerts()
        await updatePendingCount()
    }
    
    private func updatePendingCount() async {
        let count = await NotificationService.shared.getPendingAlertsCount()
        await MainActor.run {
            pendingAlertsCount = count
        }
    }
    
    private func loadUpcomingCleanings() {
        Task {
            let allBookings = await PropertyService.shared.getAllBookings()
            await MainActor.run {
                processBookings(allBookings)
            }
        }
    }
    
    private func processBookings(_ bookings: [Booking]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: today)!
        
        var cleaningDays: [UUID: [Date: [Booking]]] = [:]
        
        // Group bookings by property and checkout date
        for booking in bookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            
            // Only include future dates within 30 days
            guard checkoutDate >= today && checkoutDate <= thirtyDaysFromNow else { continue }
            
            if cleaningDays[booking.propertyId] == nil {
                cleaningDays[booking.propertyId] = [:]
            }
            if cleaningDays[booking.propertyId]![checkoutDate] == nil {
                cleaningDays[booking.propertyId]![checkoutDate] = []
            }
            cleaningDays[booking.propertyId]![checkoutDate]!.append(booking)
        }
        
        // Create CleaningDay objects
        var cleanings: [CleaningDay] = []
        for (propertyId, dateBookings) in cleaningDays {
            guard let property = PropertyService.shared.getProperty(by: propertyId) else { continue }
            
            for (checkoutDate, _) in dateBookings {
                // Check if there's a same-day checkin
                let hasCheckin = bookings.contains { booking in
                    booking.propertyId == propertyId &&
                    calendar.isDate(booking.startDate, inSameDayAs: checkoutDate)
                }
                
                let cleaning = CleaningDay(
                    id: UUID(),
                    propertyName: property.displayName,
                    date: checkoutDate,
                    isSameDayTurnover: hasCheckin
                )
                cleanings.append(cleaning)
            }
        }
        
        upcomingCleanings = cleanings.sorted { $0.date < $1.date }
    }
}

struct CleaningDay: Identifiable {
    let id: UUID
    let propertyName: String
    let date: Date
    let isSameDayTurnover: Bool
}

struct CleaningDayRow: View {
    let cleaning: CleaningDay
    
    var body: some View {
        HStack {
            if cleaning.isSameDayTurnover {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cleaning.propertyName)
                    .font(.headline)
                
                HStack {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if cleaning.isSameDayTurnover {
                        Text("• SAME-DAY TURNOVER")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Text(relativeDays)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: cleaning.date)
    }
    
    private var relativeDays: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: today, to: cleaning.date).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }
}




// MARK: - Custom Task Row
struct CustomTaskRow: View {
    let task: PeriodicTask
    let onDelete: () -> Void
    let onToggle: (Bool) -> Void
    
    @State private var isEnabled: Bool
    
    init(task: PeriodicTask, onDelete: @escaping () -> Void, onToggle: @escaping (Bool) -> Void) {
        self.task = task
        self.onDelete = onDelete
        self.onToggle = onToggle
        _isEnabled = State(initialValue: task.isEnabled)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline)
                
                HStack {
                    Text(task.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(task.scope.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    onToggle(newValue)
                }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Add Custom Task View
struct AddCustomTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskService = PeriodicTaskService.shared
    @StateObject private var propertyService = PropertyService.shared
    
    @State private var taskName = ""
    @State private var selectedFrequency: TaskFrequency = .monthly
    @State private var selectedScope: TaskScope = .global
    @State private var selectedPropertyId: UUID?
    @State private var startDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                    
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(TaskFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Section(header: Text("Apply To")) {
                    Picker("Scope", selection: $selectedScope) {
                        Text("All Properties").tag(TaskScope.global)
                        Text("Specific Property").tag(TaskScope.propertySpecific)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if selectedScope == .propertySpecific {
                        Picker("Property", selection: $selectedPropertyId) {
                            Text("Select Property").tag(nil as UUID?)
                            ForEach(propertyService.getAllProperties()) { property in
                                Text(property.displayName).tag(property.id as UUID?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Custom Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(taskName.isEmpty || (selectedScope == .propertySpecific && selectedPropertyId == nil))
                }
            }
        }
    }
    
    private func addTask() {
        let task = PeriodicTask(
            name: taskName,
            frequency: selectedFrequency,
            scope: selectedScope,
            propertyId: selectedScope == .propertySpecific ? selectedPropertyId?.uuidString : nil,
            startDate: startDate,
            isEnabled: true,
            isDefault: false
        )
        
        taskService.addTask(task)
        dismiss()
    }
}


