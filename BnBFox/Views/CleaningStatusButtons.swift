//
//  CleaningStatusButtons.swift
//  BnBFox
//
//  Created on 12/15/25.
//

import SwiftUI

struct CleaningStatusButtons: View {
    let propertyName: String
    let date: Date
    let bookingId: String
    @Binding var showTooltip: Bool
    
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @State private var tooltipTimer: Timer?
    
    var currentStatus: CleaningStatus.Status {
        statusManager.getStatus(propertyName: propertyName, date: date)?.status ?? .todo
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Button 1: To do (Red)
            StatusButton(
                icon: "spray.bottle",
                label: "To do",
                color: .red,
                isActive: currentStatus == .todo,
                isEnabled: true
            ) {
                statusManager.setStatus(
                    propertyName: propertyName,
                    date: date,
                    bookingId: bookingId,
                    status: .todo
                )
            }
            
            // Button 2: Doing... (Amber)
            StatusButton(
                icon: "spray.bottle",
                label: "Doing...",
                color: .orange,
                isActive: currentStatus == .inProgress,
                isEnabled: currentStatus != .pending
            ) {
                statusManager.setStatus(
                    propertyName: propertyName,
                    date: date,
                    bookingId: bookingId,
                    status: .inProgress
                )
                
                // Show tooltip
                withAnimation {
                    showTooltip = true
                }
                
                // Hide tooltip after 2 seconds
                tooltipTimer?.invalidate()
                tooltipTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    withAnimation {
                        showTooltip = false
                    }
                }
            }
            
            // Button 3: Done! (Green)
            StatusButton(
                icon: "spray.bottle",
                label: "Done!",
                color: .green,
                isActive: currentStatus == .done,
                isEnabled: currentStatus != .pending
            ) {
                statusManager.setStatus(
                    propertyName: propertyName,
                    date: date,
                    bookingId: bookingId,
                    status: .done
                )
            }
        }
        .overlay(alignment: .top) {
            if showTooltip {
                Text("On my way!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .offset(y: -40)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct StatusButton: View {
    let icon: String
    let label: String
    let color: Color
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                if isEnabled {
                    action()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isActive ? color.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(isActive ? color : Color.gray.opacity(0.4))
                }
            }
            .disabled(!isEnabled)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? color : .gray)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // Preview with different states
        CleaningStatusButtons(
            propertyName: "C-5",
            date: Date(),
            bookingId: UUID().uuidString,
            showTooltip: .constant(false)
        )
        
        CleaningStatusButtons(
            propertyName: "E-5",
            date: Date(),
            bookingId: UUID().uuidString,
            showTooltip: .constant(true)
        )
    }
    .padding()
}
