//
//  AppSettings.swift
//  BnBShift
//
//  Created on 12/12/2025.
//

import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var cleaningAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(cleaningAlertsEnabled, forKey: "cleaningAlertsEnabled")
            if cleaningAlertsEnabled {
                scheduleAllCleaningAlerts()
            } else {
                cancelAllCleaningAlerts()
            }
        }
    }
    
    @Published var alertSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(alertSoundEnabled, forKey: "alertSoundEnabled")
        }
    }
    
    @Published var alertTime: Date {
        didSet {
            UserDefaults.standard.set(alertTime, forKey: "alertTime")
            if cleaningAlertsEnabled {
                scheduleAllCleaningAlerts()
            }
        }
    }
    
    @Published var newBookingAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(newBookingAlertsEnabled, forKey: "newBookingAlertsEnabled")
        }
    }
    
    @Published var acFilterTaskEnabled: Bool {
        didSet {
            UserDefaults.standard.set(acFilterTaskEnabled, forKey: "acFilterTaskEnabled")
            updateACFilterTask()
        }
    }
    
    private init() {
        // Load saved settings or use defaults
        self.cleaningAlertsEnabled = UserDefaults.standard.object(forKey: "cleaningAlertsEnabled") as? Bool ?? true
        self.alertSoundEnabled = UserDefaults.standard.object(forKey: "alertSoundEnabled") as? Bool ?? true
        self.newBookingAlertsEnabled = UserDefaults.standard.object(forKey: "newBookingAlertsEnabled") as? Bool ?? true
        
        // Load AC filter task setting, or sync with existing task
        if let savedValue = UserDefaults.standard.object(forKey: "acFilterTaskEnabled") as? Bool {
            self.acFilterTaskEnabled = savedValue
        } else {
            // Sync with existing task if it exists
            let taskService = PeriodicTaskService.shared
            if let acFilterTask = taskService.tasks.first(where: { $0.isDefault && $0.name == "Change AC Filter" }) {
                self.acFilterTaskEnabled = acFilterTask.isEnabled
            } else {
                self.acFilterTaskEnabled = true // Default to enabled
            }
        }
        
        // Default alert time: 9:00 AM
        if let savedTime = UserDefaults.standard.object(forKey: "alertTime") as? Date {
            self.alertTime = savedTime
        } else {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            self.alertTime = calendar.date(from: components) ?? Date()
        }
    }
    
    private func scheduleAllCleaningAlerts() {
        NotificationService.shared.scheduleCleaningAlerts()
    }
    
    private func cancelAllCleaningAlerts() {
        NotificationService.shared.cancelAllCleaningAlerts()
    }
    
    private func updateACFilterTask() {
        // Update the AC Filter task's enabled state in PeriodicTaskService
        // The PeriodicTaskService handles notification scheduling automatically
        let taskService = PeriodicTaskService.shared
        if let acFilterTask = taskService.tasks.first(where: { $0.isDefault && $0.name == "Change AC Filter" }) {
            var updatedTask = acFilterTask
            updatedTask.isEnabled = acFilterTaskEnabled
            taskService.updateTask(updatedTask)
        }
    }
}


