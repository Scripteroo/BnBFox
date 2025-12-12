//
//  DayDetailView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct DayDetailView: View {
    let date: Date
    let activities: [PropertyActivity]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date header
                VStack(spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text(date.formatted(.dateTime.month(.wide).day()))
                        .font(.system(size: 28, weight: .bold))
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Activity list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(activities) { activity in
                            PropertyActivityCard(activity: activity)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
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

struct PropertyActivityCard: View {
    let activity: PropertyActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property header
            HStack {
                Circle()
                    .fill(activity.property.color)
                    .frame(width: 12, height: 12)
                
                Text(activity.property.displayName)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
            }
            
            // Activities
            VStack(alignment: .leading, spacing: 8) {
                if let checkout = activity.checkout {
                    ActivityRow(
                        icon: "arrow.right.circle.fill",
                        iconColor: .red,
                        title: "Check-Out",
                        time: "10:00 AM",
                        guestName: checkout.guestName
                    )
                }
                
                if let checkin = activity.checkin {
                    ActivityRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: .green,
                        title: "Check-In",
                        time: "4:00 PM",
                        guestName: checkin.guestName
                    )
                }
            }
            .padding(.leading, 24)
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let time: String
    let guestName: String?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                    
                    Text(time)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                if let guest = guestName, !guest.isEmpty {
                    Text(guest)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
}

// Data model for property activity on a specific day
struct PropertyActivity: Identifiable {
    let id = UUID()
    let property: Property
    let checkin: BookingInfo?
    let checkout: BookingInfo?
}

struct BookingInfo {
    let guestName: String?
    let booking: Booking
}
