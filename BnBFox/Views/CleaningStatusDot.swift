//
//  CleaningStatusDot.swift
//  BnBFox
//
//  Created on 12/16/2025.
//

import SwiftUI

struct CleaningStatusDot: View {
    let propertyName: String
    let checkoutDate: Date
    
    @ObservedObject var statusManager = CleaningStatusManager.shared
    
    var body: some View {
        if let status = statusManager.getStatus(propertyName: propertyName, date: checkoutDate) {
            Circle()
                .fill(statusColor(status.status))
                .frame(width: 8, height: 8)
        }
    }
    
    private func statusColor(_ status: CleaningStatus.Status) -> Color {
        switch status {
        case .pending:
            return .gray
        case .todo:
            return .red
        case .inProgress:
            return .orange  // Yellow/amber
        case .done:
            return .green
        }
    }
}

