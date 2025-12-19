//
//  PropertyActionModels.swift
//  BnBFox
//
//  Created on 12/17/2025.
//

import Foundation
import SwiftUI

// MARK: - Property Action Report

/// Container for all actions taken on a property for a specific date
struct PropertyActionReport: Identifiable, Codable, Equatable {
    let id: UUID
    let propertyId: UUID
    let propertyName: String
    let date: Date
    var completionPhoto: PhotoRecord?
    var damageReport: DamageReport?
    var pestControl: PestControlReport?
    var supplies: SuppliesReport?
    var createdAt: Date
    var updatedAt: Date
    var syncedToCloud: Bool
    
    init(propertyId: UUID, propertyName: String, date: Date) {
        self.id = UUID()
        self.propertyId = propertyId
        self.propertyName = propertyName
        self.date = date
        self.completionPhoto = nil
        self.damageReport = nil
        self.pestControl = nil
        self.supplies = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncedToCloud = false
    }
}

// MARK: - Photo Record

struct PhotoRecord: Codable, Equatable {
    let id: UUID
    let localPath: String  // Local file path
    let cloudURL: String?  // Cloud URL after sync
    let takenAt: Date
    
    init(localPath: String) {
        self.id = UUID()
        self.localPath = localPath
        self.cloudURL = nil
        self.takenAt = Date()
    }
}

// MARK: - Damage Report

struct DamageReport: Codable, Equatable {
    var description: String
    var photos: [PhotoRecord]
    var reportedAt: Date
    
    init() {
        self.description = ""
        self.photos = []
        self.reportedAt = Date()
    }
}

// MARK: - Pest Control Report

struct PestControlReport: Codable, Equatable {
    var termites: Bool
    var cockroaches: Bool
    var bedbugs: Bool
    var mice: Bool
    var other: Bool
    var otherDescription: String
    var photos: [PhotoRecord]
    var reportedAt: Date
    
    init() {
        self.termites = false
        self.cockroaches = false
        self.bedbugs = false
        self.mice = false
        self.other = false
        self.otherDescription = ""
        self.photos = []
        self.reportedAt = Date()
    }
    
    var hasAnyIssues: Bool {
        return termites || cockroaches || bedbugs || mice || other
    }
    
    var issuesList: [String] {
        var issues: [String] = []
        if termites { issues.append("Termites") }
        if cockroaches { issues.append("Cockroaches") }
        if bedbugs { issues.append("Bedbugs") }
        if mice { issues.append("Mice") }
        if other && !otherDescription.isEmpty {
            issues.append("Other: \(otherDescription)")
        } else if other {
            issues.append("Other")
        }
        return issues
    }
}

// MARK: - Supplies Report

struct SuppliesReport: Codable, Equatable {
    var toiletPaper: Bool
    var paperTowels: Bool
    var towels: Bool
    var detergent: Bool
    var acFilters: Bool
    var lightBulbs: Bool
    var cleaningSupplies: Bool
    var notes: String
    var reportedAt: Date
    
    init() {
        self.toiletPaper = false
        self.paperTowels = false
        self.towels = false
        self.detergent = false
        self.acFilters = false
        self.lightBulbs = false
        self.cleaningSupplies = false
        self.notes = ""
        self.reportedAt = Date()
    }
    
    var hasAnyLowSupplies: Bool {
        return toiletPaper || paperTowels || towels || detergent || acFilters || lightBulbs || cleaningSupplies
    }
    
    var lowSuppliesList: [String] {
        var supplies: [String] = []
        if toiletPaper { supplies.append("Toilet Paper") }
        if paperTowels { supplies.append("Paper Towels") }
        if towels { supplies.append("Towels") }
        if detergent { supplies.append("Detergent") }
        if acFilters { supplies.append("AC Filters") }
        if lightBulbs { supplies.append("Light Bulbs") }
        if cleaningSupplies { supplies.append("Cleaning Supplies") }
        return supplies
    }
}
