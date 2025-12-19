//
//  PropertyActionService.swift
//  BnBFox
//
//  Created on 12/17/2025.
//

import Foundation
import Combine

class PropertyActionService: ObservableObject {
    static let shared = PropertyActionService()
    
    private let userDefaults = UserDefaults.standard
    private let reportsKey = "property_action_reports"
    
    @Published private(set) var reports: [PropertyActionReport] = []
    
    private init() {
        loadReports()
    }
    
    // MARK: - Load/Save
    
    private func loadReports() {
        if let data = userDefaults.data(forKey: reportsKey),
           let decoded = try? JSONDecoder().decode([PropertyActionReport].self, from: data) {
            reports = decoded
        }
    }
    
    private func saveReports() {
        if let encoded = try? JSONEncoder().encode(reports) {
            userDefaults.set(encoded, forKey: reportsKey)
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Get report for a specific property and date
    func getReport(propertyId: UUID, date: Date) -> PropertyActionReport? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        return reports.first { report in
            report.propertyId == propertyId &&
            calendar.isDate(report.date, inSameDayAs: targetDate)
        }
    }
    
    /// Save or update a report
    func saveReport(_ report: PropertyActionReport) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: report.date)
        
        // Remove existing report for this property/date
        reports.removeAll { existingReport in
            existingReport.propertyId == report.propertyId &&
            calendar.isDate(existingReport.date, inSameDayAs: targetDate)
        }
        
        // Add updated report
        reports.append(report)
        saveReports()
    }
    
    /// Delete a report
    func deleteReport(propertyId: UUID, date: Date) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        reports.removeAll { report in
            report.propertyId == propertyId &&
            calendar.isDate(report.date, inSameDayAs: targetDate)
        }
        
        saveReports()
    }
    
    /// Get all reports for a property
    func getReports(for propertyId: UUID) -> [PropertyActionReport] {
        return reports.filter { $0.propertyId == propertyId }
            .sorted { $0.date > $1.date }
    }
    
    /// Get all reports
    func getAllReports() -> [PropertyActionReport] {
        return reports.sorted { $0.date > $1.date }
    }
    
    /// Get reports that need attention (damage, pests, low supplies)
    func getReportsNeedingAttention() -> [PropertyActionReport] {
        return reports.filter { report in
            // Has damage report with description or photos
            let hasDamage = (report.damageReport?.description.isEmpty == false) ||
                           (report.damageReport?.photos.isEmpty == false)
            
            // Has pest issues
            let hasPests = report.pestControl?.hasAnyIssues == true
            
            // Has low supplies
            let hasLowSupplies = report.supplies?.hasAnyLowSupplies == true
            
            return hasDamage || hasPests || hasLowSupplies
        }
        .sorted { $0.date > $1.date }
    }
    
    /// Get count of reports needing attention
    func getAttentionCount() -> Int {
        return getReportsNeedingAttention().count
    }
    
    // MARK: - Sync Status
    
    /// Mark report as synced to cloud
    func markAsSynced(_ reportId: UUID) {
        if let index = reports.firstIndex(where: { $0.id == reportId }) {
            reports[index].syncedToCloud = true
            saveReports()
        }
    }
    
    /// Get unsynced reports
    func getUnsyncedReports() -> [PropertyActionReport] {
        return reports.filter { !$0.syncedToCloud }
    }
}
