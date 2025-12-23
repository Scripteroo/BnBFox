//
//  CleaningChecklist.swift
//  BnBShift
//
//  Created on 12/22/2025.
//

import Foundation
import SwiftUI

struct CleaningChecklist: Codable, Identifiable, Equatable {
    let id: UUID
    let propertyId: UUID
    let cleaningDate: Date
    
    // Finishing Checklist
    var towelsChecked: Bool
    var toiletPaperChecked: Bool
    var paperTowelsChecked: Bool
    var handSoapChecked: Bool
    var dishSoapChecked: Bool
    var laundryDetergentChecked: Bool
    
    // Actions
    var cleaningPhotoPath: String?
    
    // Damage Report
    var damageReportText: String
    var damagePhotoPath: String?
    
    // Pest Control
    var termitesChecked: Bool
    var cockroachesChecked: Bool
    var bedbugsChecked: Bool
    var miceChecked: Bool
    var otherPestsChecked: Bool
    var pestPhotoPath: String?
    
    // Supplies
    var toiletPaperSupply: Bool
    var paperTowelsSupply: Bool
    var towelsSupply: Bool
    var detergentSupply: Bool
    var acFiltersSupply: Bool
    var lightBulbsSupply: Bool
    var cleaningSuppliesSupply: Bool
    
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        propertyId: UUID,
        cleaningDate: Date,
        towelsChecked: Bool = false,
        toiletPaperChecked: Bool = false,
        paperTowelsChecked: Bool = false,
        handSoapChecked: Bool = false,
        dishSoapChecked: Bool = false,
        laundryDetergentChecked: Bool = false,
        cleaningPhotoPath: String? = nil,
        damageReportText: String = "",
        damagePhotoPath: String? = nil,
        termitesChecked: Bool = false,
        cockroachesChecked: Bool = false,
        bedbugsChecked: Bool = false,
        miceChecked: Bool = false,
        otherPestsChecked: Bool = false,
        pestPhotoPath: String? = nil,
        toiletPaperSupply: Bool = false,
        paperTowelsSupply: Bool = false,
        towelsSupply: Bool = false,
        detergentSupply: Bool = false,
        acFiltersSupply: Bool = false,
        lightBulbsSupply: Bool = false,
        cleaningSuppliesSupply: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.propertyId = propertyId
        self.cleaningDate = cleaningDate
        self.towelsChecked = towelsChecked
        self.toiletPaperChecked = toiletPaperChecked
        self.paperTowelsChecked = paperTowelsChecked
        self.handSoapChecked = handSoapChecked
        self.dishSoapChecked = dishSoapChecked
        self.laundryDetergentChecked = laundryDetergentChecked
        self.cleaningPhotoPath = cleaningPhotoPath
        self.damageReportText = damageReportText
        self.damagePhotoPath = damagePhotoPath
        self.termitesChecked = termitesChecked
        self.cockroachesChecked = cockroachesChecked
        self.bedbugsChecked = bedbugsChecked
        self.miceChecked = miceChecked
        self.otherPestsChecked = otherPestsChecked
        self.pestPhotoPath = pestPhotoPath
        self.toiletPaperSupply = toiletPaperSupply
        self.paperTowelsSupply = paperTowelsSupply
        self.towelsSupply = towelsSupply
        self.detergentSupply = detergentSupply
        self.acFiltersSupply = acFiltersSupply
        self.lightBulbsSupply = lightBulbsSupply
        self.cleaningSuppliesSupply = cleaningSuppliesSupply
        self.completedAt = completedAt
    }
}

// MARK: - CleaningChecklistManager
class CleaningChecklistManager: ObservableObject {
    static let shared = CleaningChecklistManager()
    
    @Published private(set) var checklists: [CleaningChecklist] = []
    
    private let userDefaults = UserDefaults.standard
    private let checklistsKey = "cleaning_checklists"
    
    private init() {
        loadChecklists()
    }
    
    func loadChecklists() {
        if let data = userDefaults.data(forKey: checklistsKey),
           let decoded = try? JSONDecoder().decode([CleaningChecklist].self, from: data) {
            checklists = decoded
        }
    }
    
    func saveChecklists() {
        if let encoded = try? JSONEncoder().encode(checklists) {
            userDefaults.set(encoded, forKey: checklistsKey)
        }
    }
    
    func getChecklist(for propertyId: UUID, date: Date) -> CleaningChecklist? {
        let calendar = Calendar.current
        return checklists.first { checklist in
            checklist.propertyId == propertyId &&
            calendar.isDate(checklist.cleaningDate, inSameDayAs: date)
        }
    }
    
    func createOrUpdateChecklist(_ checklist: CleaningChecklist) {
        if let index = checklists.firstIndex(where: { $0.id == checklist.id }) {
            checklists[index] = checklist
        } else {
            checklists.append(checklist)
        }
        saveChecklists()
    }
    
    func deleteChecklist(id: UUID) {
        checklists.removeAll { $0.id == id }
        saveChecklists()
    }
}
