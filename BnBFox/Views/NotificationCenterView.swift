//
//  NotificationCenterView.swift
//  BnBFox
//
//  Created on 12/15/25.
//

import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @Environment(\.dismiss) var dismiss
    
    var onNotificationTap: (Date) -> Void
    
    var body: some View {
        let _ = BadgeManager.shared.clearBadge()  // Clear badge when opening
        NavigationView {
            List {
                let pendingStatuses = statusManager.getPendingStatuses()
                
                if pendingStatuses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("All caught up!")
                            .font(.headline)
                        Text("No pending cleaning tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(pendingStatuses) { status in
                        NotificationRow(status: status)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onNotificationTap(status.date)
                                dismiss()
                            }
                    }
                }
            }
            .navigationTitle("Cleaning Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let status: CleaningStatus
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(status.propertyName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(status.status.displayName)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch status.status {
        case .pending:
            return .gray
        case .todo:
            return .red
        case .inProgress:
            return .orange
        case .done:
            return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: status.date)
    }
}
