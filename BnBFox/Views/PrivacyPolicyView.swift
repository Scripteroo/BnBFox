//
//  PrivacyPolicyView.swift
//  BnBShift
//
//  Created on 12/23/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("Last Updated: December 23, 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Introduction
                PrivacySectionText(title: "Introduction") {
                    Text("BnBShift (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application BnBShift (\"the App\"). Please read this Privacy Policy carefully. If you do not agree with the terms of this Privacy Policy, please do not use the App.")
                }
                
                PrivacySectionText(title: "1. Information We Collect") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("We collect information that you provide directly to us and information automatically collected when you use the App.")
                            .fontWeight(.medium)
                        
                        Text("1.1. Information You Provide")
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            BulletPoint(text: "Property information (names, addresses, unit numbers)")
                            BulletPoint(text: "iCal feed URLs from third-party booking platforms")
                            BulletPoint(text: "Booking data imported from iCal feeds (guest names, check-in/check-out dates)")
                            BulletPoint(text: "Cleaning checklist data (task completion, photos, damage reports)")
                            BulletPoint(text: "Account information (if applicable)")
                        }
                        
                        Text("1.2. Automatically Collected Information")
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            BulletPoint(text: "Device information (device type, operating system version)")
                            BulletPoint(text: "Usage data (features used, time spent in the App)")
                            BulletPoint(text: "Log data (error logs, crash reports)")
                            BulletPoint(text: "App performance metrics")
                        }
                        
                        Text("1.3. Information from Third-Party Services")
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            BulletPoint(text: "Calendar data from iCal feeds (AirBnB, VRBO, Booking.com)")
                            BulletPoint(text: "This data is retrieved via the iCal URLs you provide and is stored locally on your device")
                        }
                    }
                }
                
                PrivacySectionText(title: "2. How We Use Your Information") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("We use the information we collect to:")
                        BulletPoint(text: "Provide, maintain, and improve the App's functionality")
                        BulletPoint(text: "Display your property bookings and cleaning schedules")
                        BulletPoint(text: "Synchronize calendar data from third-party booking platforms")
                        BulletPoint(text: "Send notifications about upcoming check-ins, check-outs, and cleaning tasks")
                        BulletPoint(text: "Analyze usage patterns to improve user experience")
                        BulletPoint(text: "Diagnose and fix technical issues")
                        BulletPoint(text: "Comply with legal obligations")
                    }
                }
                
                PrivacySectionText(title: "3. Data Storage and Security") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3.1. Local Storage")
                        Text("Most of your data, including property information and booking data, is stored locally on your device using Apple's Core Data framework. This data is protected by your device's security features, including encryption and passcode protection.")
                            .padding(.leading, 12)
                        
                        Text("3.2. iCloud Sync (if enabled)")
                            .padding(.top, 4)
                        Text("If you enable iCloud sync, your property data may be stored in your personal iCloud account. This data is encrypted in transit and at rest using Apple's security protocols.")
                            .padding(.leading, 12)
                        
                        Text("3.3. Security Measures")
                            .padding(.top, 4)
                        Text("We implement reasonable security measures to protect your information from unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.")
                            .padding(.leading, 12)
                    }
                }
                
                PrivacySectionText(title: "4. Information Sharing and Disclosure") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:")
                        
                        BulletPoint(text: "With your consent: When you explicitly authorize us to share information")
                        BulletPoint(text: "Service providers: With third-party vendors who perform services on our behalf (e.g., cloud hosting, analytics)")
                        BulletPoint(text: "Legal requirements: When required by law, court order, or government regulation")
                        BulletPoint(text: "Business transfers: In connection with a merger, acquisition, or sale of assets")
                        BulletPoint(text: "Protection of rights: To protect our rights, property, or safety, or that of our users")
                    }
                }
                
                PrivacySectionText(title: "5. Third-Party Services") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The App integrates with third-party services (AirBnB, VRBO, Booking.com) via iCal feeds. We do not control these third-party services and are not responsible for their privacy practices. We encourage you to review the privacy policies of these services:")
                        
                        BulletPoint(text: "AirBnB Privacy Policy: airbnb.com/privacy")
                        BulletPoint(text: "VRBO Privacy Policy: vrbo.com/legal/privacy-policy")
                        BulletPoint(text: "Booking.com Privacy Policy: booking.com/privacy.html")
                    }
                }
                
                PrivacySectionText(title: "6. Your Privacy Rights") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Depending on your location, you may have the following rights:")
                        
                        BulletPoint(text: "Access: Request a copy of the personal information we hold about you")
                        BulletPoint(text: "Correction: Request correction of inaccurate or incomplete information")
                        BulletPoint(text: "Deletion: Request deletion of your personal information")
                        BulletPoint(text: "Portability: Request transfer of your data to another service")
                        BulletPoint(text: "Objection: Object to our processing of your personal information")
                        BulletPoint(text: "Restriction: Request restriction of processing of your information")
                        
                        Text("To exercise these rights, please contact us at support@bnbshift.com")
                            .padding(.top, 8)
                            .foregroundColor(.blue)
                    }
                }
                
                PrivacySectionText(title: "7. California Privacy Rights (CCPA)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA):")
                        
                        BulletPoint(text: "Right to know what personal information is collected, used, shared, or sold")
                        BulletPoint(text: "Right to delete personal information")
                        BulletPoint(text: "Right to opt-out of the sale of personal information (we do not sell personal information)")
                        BulletPoint(text: "Right to non-discrimination for exercising your rights")
                    }
                }
                
                PrivacySectionText(title: "8. European Privacy Rights (GDPR)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you are located in the European Economic Area (EEA), you have rights under the General Data Protection Regulation (GDPR):")
                        
                        BulletPoint(text: "Legal basis for processing: We process your data based on your consent, contract performance, or legitimate interests")
                        BulletPoint(text: "Data retention: We retain your data only as long as necessary for the purposes outlined in this policy")
                        BulletPoint(text: "International transfers: Your data may be transferred to and processed in countries outside the EEA")
                        BulletPoint(text: "Right to lodge a complaint: You may file a complaint with your local data protection authority")
                    }
                }
                
                PrivacySectionText(title: "9. Children's Privacy") {
                    Text("The App is not intended for use by children under the age of 18. We do not knowingly collect personal information from children under 18. If you believe we have collected information from a child under 18, please contact us immediately, and we will take steps to delete such information.")
                }
                
                PrivacySectionText(title: "10. Data Retention") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We retain your information for as long as necessary to provide the App's services and fulfill the purposes outlined in this Privacy Policy. You may delete your data at any time by:")
                        
                        BulletPoint(text: "Deleting individual properties within the App")
                        BulletPoint(text: "Uninstalling the App from your device")
                        BulletPoint(text: "Contacting us to request data deletion")
                    }
                }
                
                PrivacySectionText(title: "11. Push Notifications") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The App may send push notifications about upcoming check-ins, check-outs, and cleaning tasks. You can control notification settings through your device's settings or within the App. We do not use notifications for marketing purposes without your explicit consent.")
                    }
                }
                
                PrivacySectionText(title: "12. Analytics and Tracking") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We may use analytics tools to understand how users interact with the App. These tools may collect information such as:")
                        
                        BulletPoint(text: "App usage patterns and feature engagement")
                        BulletPoint(text: "Device information and operating system version")
                        BulletPoint(text: "Crash reports and error logs")
                        
                        Text("This information is used solely to improve the App and is not linked to personally identifiable information.")
                            .padding(.top, 8)
                    }
                }
                
                PrivacySectionText(title: "13. Changes to This Privacy Policy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We may update this Privacy Policy from time to time. We will notify you of any material changes by:")
                        
                        BulletPoint(text: "Updating the \"Last Updated\" date at the top of this policy")
                        BulletPoint(text: "Posting a notice within the App")
                        BulletPoint(text: "Sending you a notification (if applicable)")
                        
                        Text("Your continued use of the App after changes are posted constitutes acceptance of the updated Privacy Policy.")
                            .padding(.top, 8)
                    }
                }
                
                PrivacySectionText(title: "14. International Users") {
                    Text("The App is operated in the United States. If you are located outside the United States, please be aware that information we collect will be transferred to, stored, and processed in the United States. By using the App, you consent to the transfer of your information to the United States.")
                }
                
                PrivacySectionText(title: "15. Do Not Track Signals") {
                    Text("Some web browsers have a \"Do Not Track\" feature. The App does not currently respond to Do Not Track signals, as there is no industry standard for how such signals should be interpreted.")
                }
                
                PrivacySectionText(title: "16. Contact Us") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at:")
                        
                        Text("Email: support@bnbshift.com")
                            .foregroundColor(.blue)
                        
                        Text("We will respond to your inquiry within 30 days.")
                            .padding(.top, 4)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("By using BnBShift, you acknowledge that you have read, understood, and agree to this Privacy Policy.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.bottom, 32)
            }
            .padding(20)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper views for consistent formatting
struct PrivacySectionText<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.bottom, 8)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}
