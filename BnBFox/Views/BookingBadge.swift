//
//  BookingBadge.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

struct BookingBadge: View {
    let booking: Booking
    let date: Date
    let isCompact: Bool
    
    init(booking: Booking, date: Date, isCompact: Bool = false) {
        self.booking = booking
        self.date = date
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(displayText)
                .font(.system(size: isCompact ? 8 : 9))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(booking.platform.color)
        .cornerRadius(cornerRadius, corners: roundedCorners)
    }
    
    private var displayText: String {
        if booking.isFirstDay(of: date) {
            return booking.displayName
        } else {
            return ""
        }
    }
    
    private var cornerRadius: CGFloat {
        return 4
    }
    
    private var roundedCorners: UIRectCorner {
        let isFirst = booking.isFirstDay(of: date)
        let isLast = booking.isLastDay(of: date)
        
        if isFirst && isLast {
            return .allCorners
        } else if isFirst {
            return [.topLeft, .bottomLeft]
        } else if isLast {
            return [.topRight, .bottomRight]
        } else {
            return []
        }
    }
}

// Extension to support corner-specific rounding
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
