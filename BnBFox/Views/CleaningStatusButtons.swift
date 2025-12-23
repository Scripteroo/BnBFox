//
//  CleaningStatusButtons.swift
//  BnBShift
//
//  Created on 12/16/2025.
//

import SwiftUI

struct CleaningStatusButtons: View {
    let propertyName: String
    let date: Date
    let bookingId: String
    let currentStatus: CleaningStatus.Status
    @Binding var showYellowTooltip: Bool
    @Binding var showGreenTooltip: Bool
    var onCleanTapped: (() -> Void)? = nil
    
    // Check if this checkout is in the future
    private var isFutureCheckout: Bool {
        let calendar = Calendar.current
        let checkoutDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        return checkoutDay > today
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Red button (Dirty / Sucio)
            StatusButton(
                imageName: "red-cleaning-button",
                label: "Dirty",
                sublabel: "Sucio",
                labelColor: .black,
                isSelected: currentStatus == .todo,
                isDisabled: isFutureCheckout
            ) {
                if !isFutureCheckout {
                    Task {
                        await CleaningStatusManager.shared.setStatus(
                            propertyName: propertyName,
                            date: date,
                            bookingId: bookingId,
                            status: .todo
                        )
                    }
                }
            }
            
            // Amber button (Cleaning / Limpiando)
            StatusButton(
                imageName: "amber-cleaning-button",
                label: "Cleaning",
                sublabel: "Limpiando",
                labelColor: .black,
                isSelected: currentStatus == .inProgress,
                isDisabled: isFutureCheckout
            ) {
                if !isFutureCheckout {
                    Task {
                        await CleaningStatusManager.shared.setStatus(
                            propertyName: propertyName,
                            date: date,
                            bookingId: bookingId,
                            status: .inProgress
                        )
                    }
                    
                    // Show yellow tooltip
                    withAnimation {
                        showYellowTooltip = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showYellowTooltip = false
                        }
                    }
                }
            }
            
            // Green button (Clean / Limpio)
            StatusButton(
                imageName: "green-cleaning-button",
                label: "Clean",
                sublabel: "Limpio",
                labelColor: .black,
                isSelected: currentStatus == .done,
                isDisabled: isFutureCheckout
            ) {
                if !isFutureCheckout {
                    Task {
                        await CleaningStatusManager.shared.setStatus(
                            propertyName: propertyName,
                            date: date,
                            bookingId: bookingId,
                            status: .done
                        )
                    }
                    
                    // Show green tooltip
                    withAnimation {
                        showGreenTooltip = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showGreenTooltip = false
                        }
                    }
                    
                    // Trigger checklist panel
                    onCleanTapped?()
                }
            }
        }
        .overlay(
            // Tooltip overlays
            Group {
                if showYellowTooltip {
                    VStack {
                        Text("I'm on my way! 🚗")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                            .offset(y: -60)
                    }
                    .transition(.opacity)
                }
                
                if showGreenTooltip {
                    VStack {
                        Text("Clean and Ready! ✨")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                            .offset(y: -60)
                    }
                    .transition(.opacity)
                }
            }
        )
    }
}

struct StatusButton: View {
    let imageName: String
    let label: String
    let sublabel: String
    let labelColor: Color
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Show custom image
                Image(isDisabled ? "grey-cleaning-button" : imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .opacity(isDisabled ? 1.0 : (isSelected ? 1.0 : 0.5))
                
                VStack(spacing: 2) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDisabled ? .gray : (isSelected ? labelColor : .primary))
                    
                    Text(sublabel)
                        .font(.system(size: 12))
                        .foregroundColor(isDisabled ? .gray.opacity(0.6) : .gray)
                }
            }
        }
        .disabled(isDisabled)
    }
}

