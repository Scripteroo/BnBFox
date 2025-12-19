//
//  BadgeManager.swift
//  BnBFox
//
//  Created on 12/15/25.
//

import UIKit
import UserNotifications

class BadgeManager {
    static let shared = BadgeManager()
    
    private init() {}
    
    /// Clear the app icon badge
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    /// Update badge count based on pending cleaning tasks
    func updateBadge() {
        let pendingCount = CleaningStatusManager.shared.getPendingStatuses().count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = pendingCount
        }
    }
}
