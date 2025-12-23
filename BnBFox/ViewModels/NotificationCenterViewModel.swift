//
//  NotificationCenterViewModel.swift
//  BnBFox
//
//  Main view model for NotificationCenterView
//  Implements Copilot's recommendation for single source of truth with debounced updates
//

import Foundation
import SwiftUI
import Combine

/// Main view model for the Notification Center (Cleaning Tasks view)
/// Manages all cleaning status rows and handles updates efficiently
final class NotificationCenterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var rowViewModels: [CleaningStatusRowViewModel] = []
    @Published var toastMessage: String = ""
    @Published var toastIcon: String = ""
    @Published var showToast: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let statusManager = CleaningStatusManager.shared
    
    // MARK: - Initialization
    init() {
        // Subscribe to cleaning status changes with debouncing
        // This prevents multiple rapid updates from causing repeated fetches
        NotificationCenter.default.publisher(for: NSNotification.Name("CleaningStatusChanged"))
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshRowViewModels()
            }
            .store(in: &cancellables)
        
        // Initial load
        refreshRowViewModels()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Public Methods
    
    /// Refresh the row view models from CleaningStatusManager
    /// This is called on initial load and when status changes
    func refreshRowViewModels() {
        let pendingStatuses = statusManager.getPendingStatuses()
        
        // Create or update row view models
        // Reuse existing view models where possible to maintain object identity
        var newRowViewModels: [CleaningStatusRowViewModel] = []
        
        for status in pendingStatuses {
            let id = "\(status.propertyName)-\(status.date.timeIntervalSince1970)"
            
            // Try to find existing view model
            if let existing = rowViewModels.first(where: { $0.id == id }) {
                // Update existing view model
                existing.refresh(with: status)
                newRowViewModels.append(existing)
            } else {
                // Create new view model
                let newVM = CleaningStatusRowViewModel(status: status)
                newRowViewModels.append(newVM)
            }
        }
        
        // Sort by date (earliest first)
        newRowViewModels.sort { $0.date < $1.date }
        
        // Update published property
        self.rowViewModels = newRowViewModels
    }
    
    /// Show a toast message
    func showToastMessage(_ message: String, icon: String) {
        self.toastMessage = message
        self.toastIcon = icon
        self.showToast = true
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showToast = false
        }
    }
}
