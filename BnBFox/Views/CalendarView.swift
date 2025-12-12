//
//  CalendarView.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingAdminPanel = false
    @State private var selectedProperty: Property? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Calendar content
                    if viewModel.isLoading && viewModel.bookings.isEmpty {
                        Spacer()
                        ProgressView("Loading bookings...")
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task {
                                    await viewModel.refreshData()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        Spacer()
                    } else {
                        // Legend
                        legendView
                        
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.getMonthsToDisplay(), id: \.self) { month in
                                    MonthView(
                                        month: month,
                                        bookings: viewModel.bookings
                                    )
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAdminPanel) {
            AdminPanelView()
        }
        .sheet(item: $selectedProperty) { property in
            PropertyDetailView(property: property)
                .environmentObject(PropertyService.shared)
                .environmentObject(viewModel.bookingService)
        }
        .task {
            await viewModel.loadBookings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .propertiesDidChange)) { _ in
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // Menu button
                Button(action: {
                    // Menu action placeholder
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Title
                Text("Kawama Calendar")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task {
                        await viewModel.refreshData()
                    }
                }) {
                    Image(systemName: viewModel.isLoading ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(
                            viewModel.isLoading ?
                            Animation.linear(duration: 1).repeatForever(autoreverses: false) :
                            .default,
                            value: viewModel.isLoading
                        )
                }
                
                // Settings button
                Button(action: {
                    showingAdminPanel = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Divider()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(viewModel.properties) { property in
                Button(action: {
                    selectedProperty = property
                }) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(property.color)
                            .frame(width: 20, height: 12)
                        Text(property.shortName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
