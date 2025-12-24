//
//  InfoView.swift
//  BnBShift
//
//  Created on 12/23/2025.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Logo and Title
                    HStack {
                        Image("bnbshift-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BnBShift")
                                .font(.system(size: 32, weight: .bold))
                            Text("Property Management Made Simple")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Welcome Section
                    SectionView(title: "Welcome to BnBShift") {
                        Text("BnBShift is your all-in-one property management solution for Bed & Breakfast and vacation rental properties. Seamlessly integrate calendars from AirBnB, VRBO, and Booking.com to coordinate cleaning schedules, track bookings, and manage multiple properties with ease.")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Getting Started
                    SectionView(title: "Getting Started") {
                        VStack(alignment: .leading, spacing: 12) {
                            StepView(number: 1, title: "Add Your Properties", description: "Navigate to the Properties tab and tap the + button to add your rental units.")
                            
                            StepView(number: 2, title: "Connect iCal Feeds", description: "Enter iCal URLs from AirBnB, VRBO, and Booking.com to sync your bookings automatically.")
                            
                            StepView(number: 3, title: "Set Property Details", description: "Add addresses, door codes, and other important property information.")
                            
                            StepView(number: 4, title: "Monitor Your Calendar", description: "View all bookings and cleaning schedules in one unified calendar view.")
                        }
                    }
                    
                    // Understanding the Calendar
                    SectionView(title: "Understanding the Calendar") {
                        VStack(alignment: .leading, spacing: 12) {
                            CalendarFeatureView(
                                icon: "calendar",
                                color: .green.opacity(0.3),
                                title: "Green Background",
                                description: "Indicates a day when cleaning is required. This appears on check-out days when the property needs to be prepared for the next guest."
                            )
                            
                            CalendarFeatureView(
                                icon: "circle.fill",
                                color: .orange,
                                title: "Colored Booking Bars",
                                description: "Each property has a unique color. Booking bars show the duration of guest stays, with the property name displayed on the bar."
                            )
                            
                            CalendarFeatureView(
                                icon: "circle.fill",
                                color: .blue,
                                title: "Colored Dots",
                                description: "Small colored dots at the bottom of calendar cells indicate which properties have bookings on that day. Each dot matches the property's assigned color."
                            )
                            
                            CalendarFeatureView(
                                icon: "clock",
                                color: .red,
                                title: "Check-Out Time",
                                description: "Default check-out time is 10:00 AM. Countdown timers in the Alerts tab show time remaining until check-out."
                            )
                            
                            CalendarFeatureView(
                                icon: "clock",
                                color: .green,
                                title: "Check-In Time",
                                description: "Default check-in time is 4:00 PM. Countdown timers in the Alerts tab show time remaining until check-in."
                            )
                        }
                    }
                    
                    // Using the Cleaning Checklist
                    SectionView(title: "Using the Cleaning Checklist") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When a property requires cleaning, tap the green **Clean** button to open the comprehensive cleaning checklist.")
                                .font(.body)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ChecklistItemView(title: "Task Checklist", description: "Mark off cleaning tasks as you complete them")
                                ChecklistItemView(title: "Photo Documentation", description: "Upload photos of completed cleaning work")
                                ChecklistItemView(title: "Damage Report", description: "Document any damage or issues found")
                                ChecklistItemView(title: "Pest Control", description: "Report any pest-related concerns")
                                ChecklistItemView(title: "Supplies Needed", description: "Note supplies that need restocking")
                            }
                            
                            Text("Once all tasks are complete, tap the **Finish** button to mark the property as clean and ready for the next guest.")
                                .font(.body)
                                .padding(.top, 8)
                        }
                    }
                    
                    // Property Administration
                    SectionView(title: "Property Administration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Access the Properties tab to manage your rental units:")
                                .font(.body)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                AdminFeatureView(icon: "lock.fill", title: "Lock/Unlock Properties", description: "Tap the lock icon to enable editing of property details")
                                AdminFeatureView(icon: "mappin.circle", title: "Address Management", description: "Add street address, unit number, city, state, and ZIP code")
                                AdminFeatureView(icon: "link", title: "iCal Feed Management", description: "Add, edit, or remove iCal feeds from booking platforms")
                                AdminFeatureView(icon: "plus.circle", title: "Add Custom Feeds", description: "Use the + button to add unlimited custom iCal feeds beyond the default three")
                                AdminFeatureView(icon: "xmark.circle", title: "Delete Properties", description: "Unlock a property and tap the X button to remove it")
                            }
                        }
                    }
                    
                    // iCal Setup Instructions (Anchor Point)
                    SectionView(title: "Finding iCal URLs", id: "ical-instructions") {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("To sync your bookings, you'll need to obtain iCal URLs from your booking platforms:")
                                .font(.body)
                            
                            // PDF Download Button
                            Link(destination: URL(string: "https://yourwebsite.com/bnbshift-ical-guide.pdf")!) {
                                HStack {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("📝 Download Complete PDF Guide")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text("Detailed instructions with screenshots for all platforms")
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 24))
                                }
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.vertical, 8)
                            
                            // AirBnB Instructions
                            DetailedPlatformInstructionView(
                                platform: "AirBnB",
                                color: .red,
                                icon: "house.fill"
                            )
                            
                            Divider()
                            
                            // VRBO Instructions
                            DetailedPlatformInstructionView(
                                platform: "VRBO",
                                color: .blue,
                                icon: "building.2.fill"
                            )
                            
                            Divider()
                            
                            // Booking.com Instructions
                            DetailedPlatformInstructionView(
                                platform: "Booking.com",
                                color: .orange,
                                icon: "bed.double.fill"
                            )
                        }
                    }
                    
                    // Tips & Best Practices
                    SectionView(title: "Tips & Best Practices") {
                        VStack(alignment: .leading, spacing: 8) {
                            TipView(tip: "Refresh your calendar regularly to ensure bookings are up to date")
                            TipView(tip: "Complete cleaning checklists immediately after finishing to maintain accurate records")
                            TipView(tip: "Use the Alerts tab to stay on top of upcoming check-ins and check-outs")
                            TipView(tip: "Add custom iCal feeds for any additional booking platforms you use")
                            TipView(tip: "Keep property addresses updated for accurate location information")
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Legal & Support Links
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Legal & Support")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            NavigationLink(destination: TermsOfServiceView()) {
                                LegalLinkView(title: "Terms of Service", icon: "doc.text")
                            }
                            
                            NavigationLink(destination: PrivacyPolicyView()) {
                                LegalLinkView(title: "Privacy Policy", icon: "lock.shield")
                            }
                            
                            NavigationLink(destination: SupportView()) {
                                LegalLinkView(title: "Support & Contact", icon: "questionmark.circle")
                            }
                            
                            NavigationLink(destination: AboutView()) {
                                LegalLinkView(title: "About BnBShift", icon: "info.circle")
                            }
                        }
                    }
                    
                    // Version Info
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
                .padding(20)
            }
            .navigationTitle("Information & Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionView<Content: View>: View {
    let title: String
    let id: String?
    let content: Content
    
    init(title: String, id: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.id = id
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .id(id)
            
            content
        }
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct CalendarFeatureView: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ChecklistItemView: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AdminFeatureView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PlatformInstructionView: View {
    let platform: String
    let color: Color
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(platform)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 20, alignment: .leading)
                        Text(step)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.leading, 20)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TipView: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct DetailedPlatformInstructionView: View {
    let platform: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Platform Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(platform)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            // Platform-specific content
            if platform == "AirBnB" {
                AirBnBInstructions()
            } else if platform == "VRBO" {
                VRBOInstructions()
            } else if platform == "Booking.com" {
                BookingComInstructions()
            }
        }
        .padding(16)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AirBnBInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 How to Find Your Airbnb iCal URL (Desktop / Mobile Browser)")
                .font(.headline)
                .fontWeight(.semibold)
            
            WarningBox(text: "Important: You cannot get the iCal URL inside the Airbnb mobile app — it's only available via desktop or a mobile web browser.")
            
            InstructionStep(number: 1, title: "Sign in to Airbnb", description: "Open a browser and go to airbnb.com and log into your host account.")
            
            InstructionStep(number: 2, title: "Go to Your Calendar", description: "In the top menu, click Calendar (or go to your listing, then Calendar).")
            
            InstructionStep(number: 3, title: "Select the Listing", description: "If you have multiple listings, click the specific one you want to sync.")
            
            InstructionStep(number: 4, title: "Open Availability/Sync Settings", description: "On the right hand side panel, click Availability Settings. Scroll down to find Connect calendars or Calendar sync.")
            
            InstructionStep(number: 5, title: "Find the Export Option", description: "Under Connect calendars you'll see Export calendar → This is the iCal link Airbnb gives you that ends in .ics")
            
            InstructionStep(number: 6, title: "Copy Your iCal URL", description: "Click Export calendar and then copy the full URL shown (it will end in .ics). That's your iCal link you can paste wherever needed.")
            
            URLFormatBox(example: "https://www.airbnb.com/calendar/ical/{listingID}.ics?s={uniqueString}")
            
            Text("📱 Alternative: Mobile Browser Instructions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            Text("You can use a mobile web browser like Safari or Chrome (not the Airbnb app) by opening the browser and going to airbnb.com, logging in and switching to the desktop site (via browser menu), then following the same steps above.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("🔁 Optional: Importing an External iCal into Airbnb")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            Text("If you need to import another calendar into Airbnb (like from Booking.com), go to the same Connect calendars section and choose Import calendar, then paste the external link and give it a name.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Link(destination: URL(string: "https://www.airbnb.com/help/article/99")!) {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Official Airbnb Help Article")
                    Image(systemName: "arrow.up.right")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }
}

struct VRBOInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 How to Find Your VRBO iCal URL (Calendar Export Link)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Use these steps to locate and copy your VRBO iCal URL, which allows your VRBO availability calendar to sync with other platforms.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            WarningBox(text: "Important: The VRBO iCal URL is not available in the VRBO mobile app. You must use a web browser (desktop or mobile browser).")
            
            Text("🖥️ Option 1: Desktop or Laptop (Recommended)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            InstructionStep(number: 1, title: "Sign in to VRBO", description: "Go to vrbo.com and sign in to your owner/host account.")
            
            InstructionStep(number: 2, title: "Open the Owner Dashboard", description: "Click your profile icon in the top-right corner and select Owner Dashboard. If you have multiple properties, select the property you want to sync.")
            
            InstructionStep(number: 3, title: "Open the Calendar", description: "In the left-hand navigation menu for your property, click Calendar. This will display your availability calendar.")
            
            InstructionStep(number: 4, title: "Find Calendar Import/Export", description: "Within the calendar area, look for Calendar, Import/Export, or Calendar links (wording may vary).")
            
            InstructionStep(number: 5, title: "Export the VRBO Calendar", description: "Under the Export calendar section, copy the full iCal URL provided. The link will end in .ics")
            
            URLFormatBox(example: "https://www.vrbo.com/icalendar/{propertyID}.ics")
            
            Text("📱 Option 2: Mobile Browser (Not the App)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            Text("If you're on a phone or tablet: Open Safari or Chrome (do not use the VRBO app), go to vrbo.com and sign in, enable 'Desktop site' or 'Request desktop website' in your browser menu, then follow the same steps above.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("🔁 Importing Another Calendar Into VRBO (Optional)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            Text("If you want to import an external calendar (for example, from Airbnb): Go to the same Calendar Import/Export section, choose Import calendar, paste the external iCal URL, give it a name (e.g., 'Airbnb'), and save.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Link(destination: URL(string: "https://help.vrbo.com/articles/How-do-I-import-or-export-a-calendar")!) {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Official VRBO Help Article")
                    Image(systemName: "arrow.up.right")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }
}

struct BookingComInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 How to Find Your Booking.com iCal URL (Calendar Export Link)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Use these steps to locate and copy your Booking.com iCal URL, which allows your Booking.com availability calendar to sync with other platforms.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            WarningBox(text: "Important: Booking.com calendar export links are only available through the Booking.com Extranet using a web browser. You cannot access the iCal URL from the Booking.com mobile app.")
            
            Text("🖥️ Option 1: Desktop or Laptop (Recommended)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            InstructionStep(number: 1, title: "Sign in to the Booking.com Extranet", description: "Go to admin.booking.com and sign in using your property's Extranet credentials.")
            
            InstructionStep(number: 2, title: "Open the Calendar", description: "From the left-hand menu, click Calendar & Pricing, then select Calendar. If you manage multiple properties, make sure the correct property is selected.")
            
            InstructionStep(number: 3, title: "Open Calendar Sync", description: "At the top or side of the calendar page, click Sync calendars (may also appear as Calendar sync). This is where Booking.com manages iCal imports and exports.")
            
            InstructionStep(number: 4, title: "Export the Booking.com Calendar", description: "Under the Export calendar section, you will see one or more iCal URLs. Copy the export link for the room or unit you want to sync. The link will end in .ics")
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                Text("Important: Booking.com often provides separate iCal links per room or unit, not just one for the entire property.")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            URLFormatBox(example: "https://admin.booking.com/hotel/hoteladmin/ical.html?t={uniqueString}")
            
            Text("📱 Option 2: Mobile Browser (Not the App)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            Text("If you are using a phone or tablet: Open Safari or Chrome (do not use the Booking.com app), go to admin.booking.com and sign in, enable 'Desktop site' or 'Request desktop website', then follow the same steps above.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("🔁 Importing Another Calendar Into Booking.com (Optional)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 8)
            
            Text("If you want to import an external calendar (for example, from Airbnb or VRBO): Go to Calendar & Pricing → Calendar, click Sync calendars, under Import calendar paste the external iCal URL, give it a name (e.g., 'Airbnb – Main Unit'), and save. Booking.com will periodically refresh the imported calendar automatically.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Link(destination: URL(string: "https://partner.booking.com/en-us/help/rates-availability/calendar-sync/sync-your-bookingcom-calendar-other-websites")!) {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Official Booking.com Help Article")
                    Image(systemName: "arrow.up.right")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WarningBox: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct URLFormatBox: View {
    let example: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("✔️ This URL typically looks like:")
                .font(.caption)
                .fontWeight(.semibold)
            Text(example)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.blue)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

struct LegalLinkView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Legal Views
// Note: TermsOfServiceView and PrivacyPolicyView are now in separate files

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Support & Contact")
                    .font(.title)
                    .fontWeight(.bold)
                
                Divider()
                
                Text("For support inquiries, please contact:")
                    .font(.body)
                
                Text("Email: support@bnbshift.com")
                    .font(.body)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image("bnbshift-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading) {
                        Text("BnBShift")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                
                Text("BnBShift is a comprehensive property management solution designed for vacation rental hosts and cleaning crews.")
                    .font(.body)
                
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InfoView()
}

