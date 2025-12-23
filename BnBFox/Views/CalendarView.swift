//
//  CalendarView.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI
import AVKit

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingSettings = false
    @State private var selectedProperty: Property?
    @State private var showingNotificationCenter = false
    @State private var selectedDate: Date?
    @State private var dayDetailItem: DayDetailItem?  // NEW - for showing day detail
    //@ObservedObject var statusManager = CleaningStatusManager.shared // removed extraneous and slow!
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.bookings.isEmpty {
                    AnimatedLoadingScreen()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error Loading Bookings")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task {
                                await viewModel.loadBookings()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    // Header
                    headerView
                    
                    // Legend
                    legendView
                    
                    Divider()
                    
                    // Calendar with progressive loading
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.getMonthsToDisplay(), id: \.self) { month in
                                    MonthView(
                                        month: month,
                                        bookings: viewModel.bookings
                                    )
                                    .id(month)
                                }
                            }
                        }
                        .onAppear {
                            // Scroll to current month when view appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(viewModel.currentMonth.startOfMonth(), anchor: .top)
                            }
                        }
                        .onChange(of: selectedDate) { newDate in
                            if let date = newDate {
                                // Scroll to the month
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(date.startOfMonth(), anchor: .top)
                                }
                                
                                // Then open the day detail view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    let activities = getActivitiesForDate(date)
                                    if !activities.isEmpty {
                                        dayDetailItem = DayDetailItem(date: date, activities: activities)
                                    }
                                    selectedDate = nil  // Reset for next time
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadBookings()
            }
            .refreshable {
                await viewModel.loadBookings()
            }
            /*           .sheet(item: $selectedProperty) { property in
             PropertyDetailView(
             property: property,
             bookings: viewModel.bookings
             )
             .environmentObject(PropertyService.shared)
             }
             */
            // NEW CODE - Replace with this:
            .sheet(item: $selectedProperty) { property in
                PropertyDetailView(property: property)
                    .environmentObject(PropertyService.shared)
            }
            
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNotificationCenter) {
                NotificationCenterView { date in
                    showingNotificationCenter = false  // Close notification center first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedDate = date  // Then trigger navigation
                    }
                }
            }
            .sheet(item: $dayDetailItem) { item in  // NEW - show day detail
                DayDetailView(date: item.date, activities: item.activities)
            }
        }
    }
    
    // NEW - Helper function to get activities for a date
    private func getActivitiesForDate(_ date: Date) -> [PropertyActivity] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        var activities: [PropertyActivity] = []
        
        for property in viewModel.properties {
            let propertyBookings = viewModel.bookings.filter { $0.propertyId == property.id }
            
            var checkin: BookingInfo?
            var checkout: BookingInfo?
            
            for booking in propertyBookings {
                let bookingStart = calendar.startOfDay(for: booking.startDate)
                let bookingEnd = calendar.startOfDay(for: booking.endDate)
                
                // Check-in on this date
                if calendar.isDate(bookingStart, inSameDayAs: dayStart) {
                    checkin = BookingInfo(guestName: booking.guestName, booking: booking)
                }
                
                // Check-out on this date
                if calendar.isDate(bookingEnd, inSameDayAs: dayStart) {
                    checkout = BookingInfo(guestName: booking.guestName, booking: booking)
                }
            }
            
            // Only add if there's activity
            if checkin != nil || checkout != nil {
                activities.append(PropertyActivity(
                    property: property,
                    checkin: checkin,
                    checkout: checkout
                ))
            }
        }
        
        // Sort by property name
        return activities.sorted { $0.property.displayName < $1.property.displayName }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                
                // Title
                Text("BnBFox")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                // Refresh button
                Button(action: {
                    Task {
                        await viewModel.loadBookings()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.properties) { property in
                    Button(action: {
                        selectedProperty = property
                    }) {
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(property.color)
                                .frame(width: 40, height: 20)
                            Text(property.shortName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .background(Color(UIColor.systemBackground))
    }
}

    
// MARK: - Animated Loading Screen with Video
struct AnimatedLoadingScreen: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Full screen video player
                if let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                } else {
                    // Fallback while video loads
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Spacer()
                
                // Text overlay at bottom
                VStack(spacing: 12) {
                    Text("Loading your Kawama Calendar")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    Text("Fetching booking data...")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 8)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            setupVideoPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupVideoPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "cleaning-supplies", withExtension: "mov") else {
            print("Error: Could not find cleaning-supplies.mov")
            return
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        self.player = player
        player.play()
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}







