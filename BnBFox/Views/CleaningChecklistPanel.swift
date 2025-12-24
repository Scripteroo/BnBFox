//
//  CleaningChecklistPanel.swift
//  BnBShift
//
//  Created on 12/22/2025.
//

import SwiftUI
import PhotosUI

struct CleaningChecklistPanel: View {
    let property: Property
    let date: Date
    @Binding var isExpanded: Bool
    
    @State private var checklist: CleaningChecklist
    @State private var showImagePicker = false
    @State private var imagePickerType: ImagePickerType = .cleaning
    @State private var selectedImage: UIImage?
    
    @StateObject private var checklistManager = CleaningChecklistManager.shared
    
    enum ImagePickerType {
        case cleaning
        case damage
        case pest
    }
    
    init(property: Property, date: Date, isExpanded: Binding<Bool>) {
        self.property = property
        self.date = date
        self._isExpanded = isExpanded
        
        // Load existing checklist or create new one
        let existing = CleaningChecklistManager.shared.getChecklist(for: property.id, date: date)
        _checklist = State(initialValue: existing ?? CleaningChecklist(propertyId: property.id, cleaningDate: date))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Finishing Checklist")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Periodic Maintenance Tasks (if any due)
            PeriodicTasksSection(propertyId: property.id.uuidString, date: date)
            
            // Finishing Checklist Section
            VStack(alignment: .leading, spacing: 12) {
                ChecklistItem(text: "Towels - 6 bath, 2 hand, 6 beach", isChecked: $checklist.towelsChecked)
                ChecklistItem(text: "Toilet paper 2 + 2 rolls", isChecked: $checklist.toiletPaperChecked)
                ChecklistItem(text: "Paper towels 1 roll in kitchen", isChecked: $checklist.paperTowelsChecked)
                ChecklistItem(text: "Hand soap", isChecked: $checklist.handSoapChecked)
                ChecklistItem(text: "Dish soap & dishwasher soap", isChecked: $checklist.dishSoapChecked)
                ChecklistItem(text: "Laundry detergent", isChecked: $checklist.laundryDetergentChecked)
            }
            
            Divider()
            
            // Actions Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Actions")
                    .font(.headline)
                
                HStack {
                    Text("Log photo of completed\ncleaning from inside front door.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        imagePickerType = .cleaning
                        showImagePicker = true
                    }) {
                        Image(systemName: checklist.cleaningPhotoPath != nil ? "checkmark.circle.fill" : "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(checklist.cleaningPhotoPath != nil ? .green : .gray)
                    }
                }
            }
            
            Divider()
            
            // Damage Report Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Damage report")
                    .font(.headline)
                
                TextEditor(text: $checklist.damageReportText)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                HStack {
                    Spacer()
                    Button(action: {
                        imagePickerType = .damage
                        showImagePicker = true
                    }) {
                        Image(systemName: checklist.damagePhotoPath != nil ? "checkmark.circle.fill" : "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(checklist.damagePhotoPath != nil ? .green : .gray)
                    }
                }
            }
            
            Divider()
            
            // Pest Control Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Pest Control")
                    .font(.headline)
                
                ChecklistItem(text: "Termites", isChecked: $checklist.termitesChecked)
                ChecklistItem(text: "Cockroaches", isChecked: $checklist.cockroachesChecked)
                ChecklistItem(text: "Bedbugs", isChecked: $checklist.bedbugsChecked)
                ChecklistItem(text: "Mice", isChecked: $checklist.miceChecked)
                ChecklistItem(text: "Other", isChecked: $checklist.otherPestsChecked)
                
                HStack {
                    Image(systemName: "ant.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        imagePickerType = .pest
                        showImagePicker = true
                    }) {
                        Image(systemName: checklist.pestPhotoPath != nil ? "checkmark.circle.fill" : "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(checklist.pestPhotoPath != nil ? .green : .gray)
                    }
                }
            }
            
            Divider()
            
            // Supplies Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Supplies")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        ChecklistItem(text: "Toilet Paper", isChecked: $checklist.toiletPaperSupply)
                        ChecklistItem(text: "Towels", isChecked: $checklist.towelsSupply)
                        ChecklistItem(text: "AC Filters", isChecked: $checklist.acFiltersSupply)
                        ChecklistItem(text: "Cleaning Supplies", isChecked: $checklist.cleaningSuppliesSupply)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ChecklistItem(text: "Paper Towels", isChecked: $checklist.paperTowelsSupply)
                        ChecklistItem(text: "Detergent", isChecked: $checklist.detergentSupply)
                        ChecklistItem(text: "Light Bulbs", isChecked: $checklist.lightBulbsSupply)
                    }
                }
            }
            
            // Finish Button
            Button(action: finishChecklist) {
                HStack {
                    Spacer()
                    Image("finish-button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    Spacer()
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                saveImage(image, for: imagePickerType)
            }
        }
        .onChange(of: checklist) { _ in
            checklistManager.createOrUpdateChecklist(checklist)
        }
    }
    
    private func saveImage(_ image: UIImage, for type: ImagePickerType) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = "\(property.id.uuidString)_\(date.timeIntervalSince1970)_\(type).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            
            switch type {
            case .cleaning:
                checklist.cleaningPhotoPath = fileURL.path
            case .damage:
                checklist.damagePhotoPath = fileURL.path
            case .pest:
                checklist.pestPhotoPath = fileURL.path
            }
            
            checklistManager.createOrUpdateChecklist(checklist)
        } catch {
            print("Error saving image: \(error)")
        }
    }
    
    private func finishChecklist() {
        checklist.completedAt = Date()
        checklistManager.createOrUpdateChecklist(checklist)
        isExpanded = false
    }
}

// MARK: - ChecklistItem
struct ChecklistItem: View {
    let text: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .gray)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Note: ImagePicker already exists in the project, so we use the existing one


// MARK: - Periodic Tasks Section
struct PeriodicTasksSection: View {
    let propertyId: String
    let date: Date
    
    @StateObject private var taskService = PeriodicTaskService.shared
    @State private var completedTasks: Set<UUID> = []
    
    var dueTasks: [PeriodicTask] {
        taskService.getTasksDue(on: date, for: propertyId)
    }
    
    var body: some View {
        if !dueTasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Maintenance Tasks")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                ForEach(dueTasks) { task in
                    PeriodicTaskItem(
                        task: task,
                        isCompleted: completedTasks.contains(task.id),
                        onToggle: {
                            if completedTasks.contains(task.id) {
                                completedTasks.remove(task.id)
                            } else {
                                completedTasks.insert(task.id)
                                taskService.markTaskCompleted(task, on: date)
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
        }
    }
}

// MARK: - Periodic Task Item
struct PeriodicTaskItem: View {
    let task: PeriodicTask
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .orange)
                
                Text(task.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

