//
//  BnBFoxApp.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

@main
struct BnBFoxApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var statusManager = CleaningStatusManager.shared
    @State private var selectedTab = 0
    @State private var selectedDate: Date?
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(0)
                
                AdminPanelView()
                    .tabItem {
                        Label("Properties", systemImage: "house")
                    }
                    .tag(1)
                
                NotificationCenterView { date in
                    selectedDate = date
                    selectedTab = 0  // Switch to Calendar tab
                }
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
                .badge(statusManager.getPendingStatuses().count)
                .tag(2)
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
            }
        }
    }
}
