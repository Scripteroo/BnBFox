//
//  BnBFoxApp.swift
//  BnBFox
//
//  Created on 12/17/2025.
//  Updated to use NavigationStack (iOS 16+) with correct DayDetailView initializer
//

import SwiftUI
import UserNotifications

@main
struct BnBFoxApp: App {
    @StateObject private var navigationState = NavigationState()
    
    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationDelegate.shared.navigationState = NavigationState.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationState)
        }
    }
}

// MARK: - Navigation State

class NavigationState: ObservableObject {
    static let shared = NavigationState()
    
    @Published var selectedPropertyId: UUID?
    @Published var selectedDate: Date?
    @Published var shouldNavigateToDayDetail = false
    @Published var navigationPath = NavigationPath()
    
    func navigateToCleaningTask(propertyId: UUID, date: Date) {
        DispatchQueue.main.async {
            self.selectedPropertyId = propertyId
            self.selectedDate = date
            self.shouldNavigateToDayDetail = true
        }
    }
    
    func resetNavigation() {
        selectedPropertyId = nil
        selectedDate = nil
        shouldNavigateToDayDetail = false
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var navigationState: NavigationState?
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a cleaning notification
        if let type = userInfo["type"] as? String,
           type == "cleaning",
           let propertyIdString = userInfo["propertyId"] as? String,
           let propertyId = UUID(uuidString: propertyIdString),
           let dateTimestamp = userInfo["date"] as? TimeInterval {
            
            let date = Date(timeIntervalSince1970: dateTimestamp)
            
            // Navigate to the specific property and date
            navigationState?.navigateToCleaningTask(propertyId: propertyId, date: date)
        }
        
        completionHandler()
    }
}

// MARK: - Content View with Navigation

struct ContentView: View {
    @EnvironmentObject var navigationState: NavigationState
    @StateObject private var calendarViewModel = CalendarViewModel()
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationState.navigationPath) {
                CalendarView()
                    .navigationDestination(isPresented: $navigationState.shouldNavigateToDayDetail) {
                        if let date = navigationState.selectedDate {
                            DayDetailView(
                                date: date,
                                activities: getActivitiesForDay(date: date)
                            )
                            .onDisappear {
                                navigationState.resetNavigation()
                            }
                        } else {
                            Text("Unable to load property details")
                                .foregroundColor(.gray)
                        }
                    }
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(0)
            
            NavigationStack {
                Text("Properties")
                    .font(.largeTitle)
            }
            .tabItem {
                Label("Properties", systemImage: "house.fill")
            }
            .tag(1)
            
            NavigationStack {
                NotificationCenterView(onNotificationTap: { date in
                    // When notification is tapped, navigate to that date
                    navigationState.selectedDate = date
                    navigationState.shouldNavigateToDayDetail = true
                    selectedTab = 0  // Switch to calendar tab
                })
            }
            .tabItem {
                Label("Alerts", systemImage: "bell.fill")
            }
            .badge(statusManager.getPendingStatuses().count)
            .tag(2)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .onChange(of: navigationState.shouldNavigateToDayDetail) { shouldNavigate in
            if shouldNavigate {
                // Switch to calendar tab
                selectedTab = 0
            }
        }
        .task {
            // Load bookings when app starts
            await calendarViewModel.loadBookings()
        }
    }
    
    // Build activities array for DayDetailView
    // This follows the same pattern as CalendarView's getActivitiesForDay
    private func getActivitiesForDay(date: Date) -> [PropertyActivity] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        var activities: [PropertyActivity] = []
        
        // If we have a specific property selected, filter to just that property
        let properties: [Property]
        if let selectedPropertyId = navigationState.selectedPropertyId {
            if let property = PropertyService.shared.getProperty(by: selectedPropertyId) {
                properties = [property]
            } else {
                properties = calendarViewModel.properties
            }
        } else {
            properties = calendarViewModel.properties
        }
        
        for property in properties {
            let propertyBookings = calendarViewModel.bookings.filter { $0.propertyId == property.id }
            
            var checkin: BookingInfo?
            var checkout: BookingInfo?
            
            for booking in propertyBookings {
                let bookingStart = calendar.startOfDay(for: booking.startDate)
                let bookingEnd = calendar.startOfDay(for: booking.endDate)
                
                // Check-in on this date
                if calendar.isDate(bookingStart, inSameDayAs: dayStart) {
                    checkin = BookingInfo(guestName: booking.guestName, booking: booking)
                }
                
                // Check-out on this date
                if calendar.isDate(bookingEnd, inSameDayAs: dayStart) {
                    checkout = BookingInfo(guestName: booking.guestName, booking: booking)
                }
            }
            
            // Only add if there's activity
            if checkin != nil || checkout != nil {
                activities.append(PropertyActivity(
                    property: property,
                    checkin: checkin,
                    checkout: checkout
                ))
            }
        }
        
        // Sort by property name
        return activities.sorted { $0.property.displayName < $1.property.displayName }
    }
}
