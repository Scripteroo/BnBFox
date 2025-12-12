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
    @State private var showingAdminPanel = false
    @State private var selectedProperty: Property?
    
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
                    
                    // Calendar
                    ScrollView {
                        MonthView(
                            month: viewModel.currentMonth,
                            bookings: viewModel.bookings
                        )
                        .environmentObject(viewModel)
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
            .sheet(isPresented: $showingAdminPanel) {
                AdminPanelView()
                    .environmentObject(PropertyService.shared)
                    .onDisappear {
                        Task {
                            await viewModel.loadBookings()
                        }
                    }
            }
            .sheet(item: $selectedProperty) { property in
                PropertyDetailView(
                    property: property,
                    bookings: viewModel.bookings
                )
                .environmentObject(PropertyService.shared)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Menu button (placeholder)
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Title
                Text("Kawama Calendar")
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
        guard let videoURL = Bundle.main.url(forResource: "sea-turtle-swimming", withExtension: "mov") else {
            print("Error: Could not find sea-turtle-swimming.mov")
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
