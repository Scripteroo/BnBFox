//
//  PropertyDetailView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct PropertyDetailView: View {
    let property: Property
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Property Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(property.color)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(property.displayName)
                                    .font(.system(size: 24, weight: .bold))
                                Text(property.complexName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Property Information
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Property Information")
                        
                        InfoRow(label: "Unit", value: property.shortName)
                        InfoRow(label: "Complex", value: property.complexName)
                        InfoRow(label: "Full Name", value: property.displayName)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Calendar Sources
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Calendar Sources")
                        
                        ForEach(property.sources) { source in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(source.platform.color)
                                    Text(source.platform.displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(source.url.absoluteString)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        if property.sources.isEmpty {
                            Text("No calendar sources configured")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Owner Contact (Placeholder for future implementation)
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Owner Contact")
                        
                        Text("Owner contact information will be added here")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .italic()
                        
                        // Placeholder for future fields:
                        // - Owner name
                        // - Phone number
                        // - Email
                        // - Emergency contact
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}
