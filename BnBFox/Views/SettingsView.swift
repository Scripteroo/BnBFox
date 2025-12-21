//
//  SettingsView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var pendingAlertsCount = 0
    
    var body: some View {
        NavigationView {
            Form {
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
                    
                    if settings.cleaningAlertsEnabled {
                        HStack {
                            Text("Pending Alerts")
                            Spacer()
                            Text("\(pendingAlertsCount)")
                                .foregroundColor(.secondary)
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
                
                // Product Backlog Section
                Section(header: Text("Coming Soon")) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.gray)
                        Text("Completion Photos")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Planned")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.gray)
                        Text("Damage Reporting")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Planned")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("3.3")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await updatePendingCount()
            }
        }
    }
    
    private func updatePendingCount() async {
        pendingAlertsCount = await NotificationService.shared.getPendingAlertsCount()
    }
}

#Preview {
    SettingsView()
}


