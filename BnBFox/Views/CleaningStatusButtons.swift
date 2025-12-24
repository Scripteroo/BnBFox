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
    let bookingId: String?  // nil if no booking
    let currentStatus: CleaningStatus.Status
    @Binding var showYellowTooltip: Bool
    @Binding var showGreenTooltip: Bool
    var onCleanTapped: (() -> Void)? = nil
    
    @State private var showPastDateToast = false
    
    // Check if there's no booking (no checkout)
    private var hasNoBooking: Bool {
        bookingId == nil || bookingId == ""
    }
    
    // Check if this checkout is in the future
    private var isFutureCheckout: Bool {
        let calendar = Calendar.current
        let checkoutDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        return checkoutDay > today
    }
    
    var body: some View {
        if hasNoBooking {
            // Show grayed-out icons with DONE checkmark
            VStack(spacing: 16) {
                // Grayed-out cleaning status buttons
                HStack(spacing: 20) {
                    GrayedOutStatusButton(label: "Dirty", sublabel: "Sucio") {
                        showPastDateToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showPastDateToast = false
                        }
                    }
                    
                    GrayedOutStatusButton(label: "Cleaning", sublabel: "Limpiando") {
                        showPastDateToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showPastDateToast = false
                        }
                    }
                    
                    GrayedOutStatusButton(label: "Clean", sublabel: "Limpio") {
                        showPastDateToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showPastDateToast = false
                        }
                    }
                }
                
                // Completion message
                Text(NSLocalizedString("turnaround_completed_on", comment: "Completion message") + "  \(formattedDate)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.top, 4)
                
                // Large DONE checkmark
                VStack(spacing: 8) {
                    Image("done-button")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
                    Text(NSLocalizedString("done_exclamation", comment: "Completion text"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0.7, blue: 0))
                }
                .padding(.top, 16)
            }
            .overlay(
                // Toast message
                Group {
                    if showPastDateToast {
                        VStack {
                            Spacer()
                            Text(NSLocalizedString("unit_completed_past", comment: "Toast message"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(12)
                                .padding(.bottom, 20)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: showPastDateToast)
                    }
                }
            )
        } else {
            // Normal colored cleaning status buttons
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
                                bookingId: bookingId ?? "",
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
                                bookingId: bookingId ?? "",
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
                                bookingId: bookingId ?? "",
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
                            Text(NSLocalizedString("on_my_way", comment: "Tooltip"))
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
                            Text(NSLocalizedString("clean_and_ready", comment: "Tooltip"))
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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
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

struct GrayedOutStatusButton: View {
    let label: String
    let sublabel: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Gray cleaning icon
                Image("grey-cleaning-button")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .opacity(0.5)
                
                VStack(spacing: 2) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text(sublabel)
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
    }
}


