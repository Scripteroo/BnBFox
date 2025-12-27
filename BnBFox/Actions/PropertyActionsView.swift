//
//  PropertyActionsView.swift
//  BnBFox
//
//  Created on 12/17/2025.
//

import SwiftUI
import PhotosUI

struct PropertyActionsView: View {
    let property: Property
    let date: Date
    
    @StateObject private var actionService = PropertyActionService.shared
    @State private var report: PropertyActionReport
    @State private var showingCompletionCamera = false
    @State private var showingDamageCamera = false
    @State private var showingPestCamera = false
    @State private var selectedCompletionImage: UIImage?
    @State private var selectedDamageImages: [UIImage] = []
    @State private var selectedPestImages: [UIImage] = []
    
    init(property: Property, date: Date) {
        self.property = property
        self.date = date
        
        // Load existing report or create new one
        let existingReport = PropertyActionService.shared.getReport(
            propertyId: property.id,
            date: date
        ) ?? PropertyActionReport(
            propertyId: property.id,
            propertyName: property.displayName,
            date: date
        )
        _report = State(initialValue: existingReport)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            Text("Actions")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal)
                .padding(.top, 8)
            
            VStack(spacing: 16) {
                // Completion Photo
                completionPhotoSection
                
                Divider()
                    .padding(.horizontal)
                
                // Damage Report
                damageReportSection
                
                Divider()
                    .padding(.horizontal)
                
                // Pest Control
                pestControlSection
                
                Divider()
                    .padding(.horizontal)
                
                // Supplies
                suppliesSection
            }
            .padding(.horizontal)
        }
        .onChange(of: report) { _ in
            saveReport()
        }
    }
    
    // MARK: - Completion Photo Section
    
    private var completionPhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log photo of completed")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Text("cleaning from inside front door.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingCompletionCamera = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
            }
            
            // Show photo if taken
            if let photo = report.completionPhoto,
               let uiImage = loadImage(from: photo.localPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(
                        Button(action: {
                            report.completionPhoto = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.red))
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            }
        }
        .sheet(isPresented: $showingCompletionCamera) {
            ImagePicker(image: $selectedCompletionImage, sourceType: .camera)
        }
        .onChange(of: selectedCompletionImage) { image in
            if let image = image {
                saveCompletionPhoto(image)
            }
        }
    }
    
    // MARK: - Damage Report Section
    
    private var damageReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Damage report")
                .font(.system(size: 18, weight: .semibold))
            
            HStack(alignment: .top, spacing: 12) {
                TextEditor(text: Binding(
                    get: { report.damageReport?.description ?? "" },
                    set: { newValue in
                        if report.damageReport == nil {
                            report.damageReport = DamageReport()
                        }
                        report.damageReport?.description = newValue
                    }
                ))
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .font(.system(size: 15))
                
                Button(action: {
                    showingDamageCamera = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
            }
            
            // Show damage photos
            if let photos = report.damageReport?.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos, id: \.id) { photo in
                            if let uiImage = loadImage(from: photo.localPath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        Button(action: {
                                            removeDamagePhoto(photo)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.red))
                                        }
                                        .padding(4),
                                        alignment: .topTrailing
                                    )
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDamageCamera) {
            MultiImagePicker(images: $selectedDamageImages)
        }
        .onChange(of: selectedDamageImages) { images in
            if !images.isEmpty {
                saveDamagePhotos(images)
                selectedDamageImages = []
            }
        }
    }
    
    // MARK: - Pest Control Section
    
    private var pestControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pest Control")
                .font(.system(size: 18, weight: .semibold))
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.pestControl?.termites ?? false },
                            set: { newValue in
                                if report.pestControl == nil {
                                    report.pestControl = PestControlReport()
                                }
                                report.pestControl?.termites = newValue
                            }
                        ),
                        label: "Termites"
                    )
                    
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.pestControl?.cockroaches ?? false },
                            set: { newValue in
                                if report.pestControl == nil {
                                    report.pestControl = PestControlReport()
                                }
                                report.pestControl?.cockroaches = newValue
                            }
                        ),
                        label: "Cockroaches"
                    )
                    
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.pestControl?.bedbugs ?? false },
                            set: { newValue in
                                if report.pestControl == nil {
                                    report.pestControl = PestControlReport()
                                }
                                report.pestControl?.bedbugs = newValue
                            }
                        ),
                        label: "Bedbugs"
                    )
                    
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.pestControl?.mice ?? false },
                            set: { newValue in
                                if report.pestControl == nil {
                                    report.pestControl = PestControlReport()
                                }
                                report.pestControl?.mice = newValue
                            }
                        ),
                        label: "Mice"
                    )
                    
                    HStack(spacing: 8) {
                        CheckboxRow(
                            isChecked: Binding(
                                get: { report.pestControl?.other ?? false },
                                set: { newValue in
                                    if report.pestControl == nil {
                                        report.pestControl = PestControlReport()
                                    }
                                    report.pestControl?.other = newValue
                                }
                            ),
                            label: "Other"
                        )
                        
                        if report.pestControl?.other == true {
                            TextField("Describe...", text: Binding(
                                get: { report.pestControl?.otherDescription ?? "" },
                                set: { newValue in
                                    report.pestControl?.otherDescription = newValue
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 14))
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "ant.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showingPestCamera = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Show pest photos
            if let photos = report.pestControl?.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos, id: \.id) { photo in
                            if let uiImage = loadImage(from: photo.localPath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        Button(action: {
                                            removePestPhoto(photo)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.red))
                                        }
                                        .padding(4),
                                        alignment: .topTrailing
                                    )
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPestCamera) {
            MultiImagePicker(images: $selectedPestImages)
        }
        .onChange(of: selectedPestImages) { images in
            if !images.isEmpty {
                savePestPhotos(images)
                selectedPestImages = []
            }
        }
    }
    
    // MARK: - Supplies Section
    
    private var suppliesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supplies")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.supplies?.toiletPaper ?? false },
                            set: { newValue in
                                if report.supplies == nil {
                                    report.supplies = SuppliesReport()
                                }
                                report.supplies?.toiletPaper = newValue
                            }
                        ),
                        label: "Toilet Paper"
                    )
                    
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.supplies?.paperTowels ?? false },
                            set: { newValue in
                                if report.supplies == nil {
                                    report.supplies = SuppliesReport()
                                }
                                report.supplies?.paperTowels = newValue
                            }
                        ),
                        label: "Paper Towels"
                    )
                }
                
                HStack(spacing: 16) {
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.supplies?.towels ?? false },
                            set: { newValue in
                                if report.supplies == nil {
                                    report.supplies = SuppliesReport()
                                }
                                report.supplies?.towels = newValue
                            }
                        ),
                        label: "Towels"
                    )
                    
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.supplies?.detergent ?? false },
                            set: { newValue in
                                if report.supplies == nil {
                                    report.supplies = SuppliesReport()
                                }
                                report.supplies?.detergent = newValue
                            }
                        ),
                        label: "Detergent"
                    )
                }
                
                HStack(spacing: 16) {
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.supplies?.acFilters ?? false },
                            set: { newValue in
                                if report.supplies == nil {
                                    report.supplies = SuppliesReport()
                                }
                                report.supplies?.acFilters = newValue
                            }
                        ),
                        label: "AC Filters"
                    )
                    
                    CheckboxRow(
                        isChecked: Binding(
                            get: { report.supplies?.lightBulbs ?? false },
                            set: { newValue in
                                if report.supplies == nil {
                                    report.supplies = SuppliesReport()
                                }
                                report.supplies?.lightBulbs = newValue
                            }
                        ),
                        label: "Light Bulbs"
                    )
                }
                
                CheckboxRow(
                    isChecked: Binding(
                        get: { report.supplies?.cleaningSupplies ?? false },
                        set: { newValue in
                            if report.supplies == nil {
                                report.supplies = SuppliesReport()
                            }
                            report.supplies?.cleaningSupplies = newValue
                        }
                    ),
                    label: "Cleaning Supplies"
                )
            }
            
            // Notes field
            TextField("Additional notes...", text: Binding(
                get: { report.supplies?.notes ?? "" },
                set: { newValue in
                    if report.supplies == nil {
                        report.supplies = SuppliesReport()
                    }
                    report.supplies?.notes = newValue
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.system(size: 14))
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveReport() {
        report.updatedAt = Date()
        actionService.saveReport(report)
    }
    
    private func saveCompletionPhoto(_ image: UIImage) {
        if let path = saveImageToDocuments(image, prefix: "completion") {
            report.completionPhoto = PhotoRecord(localPath: path)
        }
    }
    
    private func saveDamagePhotos(_ images: [UIImage]) {
        if report.damageReport == nil {
            report.damageReport = DamageReport()
        }
        
        for image in images {
            if let path = saveImageToDocuments(image, prefix: "damage") {
                report.damageReport?.photos.append(PhotoRecord(localPath: path))
            }
        }
    }
    
    private func removeDamagePhoto(_ photo: PhotoRecord) {
        report.damageReport?.photos.removeAll { $0.id == photo.id }
        deleteImageFromDocuments(photo.localPath)
    }
    
    private func savePestPhotos(_ images: [UIImage]) {
        if report.pestControl == nil {
            report.pestControl = PestControlReport()
        }
        
        for image in images {
            if let path = saveImageToDocuments(image, prefix: "pest") {
                report.pestControl?.photos.append(PhotoRecord(localPath: path))
            }
        }
    }
    
    private func removePestPhoto(_ photo: PhotoRecord) {
        report.pestControl?.photos.removeAll { $0.id == photo.id }
        deleteImageFromDocuments(photo.localPath)
    }
    
    private func saveImageToDocuments(_ image: UIImage, prefix: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let filename = "\(prefix)_\(UUID().uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            Logger.log("Error saving image: \(error)")
            return nil
        }
    }
    
    private func loadImage(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    
    private func deleteImageFromDocuments(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}

// MARK: - Checkbox Row Component

struct CheckboxRow: View {
    @Binding var isChecked: Bool
    let label: String
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isChecked ? .blue : .gray)
                
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Image Picker (Single)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Multi Image Picker

struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
