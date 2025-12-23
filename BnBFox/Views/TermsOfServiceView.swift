//
//  TermsOfServiceView.swift
//  BnBShift
//
//  Created on 12/23/2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("Last Updated: December 23, 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Introduction
                SectionText(title: "1. Acceptance of Terms") {
                    Text("By downloading, installing, or using BnBShift (\"the App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, do not use the App.")
                }
                
                SectionText(title: "2. Description of Service") {
                    Text("BnBShift is a property management application designed to help vacation rental property owners and cleaning crews coordinate schedules, track bookings, and manage cleaning tasks. The App integrates with third-party calendar services including AirBnB, VRBO, and Booking.com via iCal feeds.")
                }
                
                SectionText(title: "3. User Accounts and Registration") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3.1. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.")
                        Text("3.2. You must provide accurate, current, and complete information during registration and keep your account information updated.")
                        Text("3.3. You must be at least 18 years old to use this App.")
                        Text("3.4. You agree to notify us immediately of any unauthorized use of your account.")
                    }
                }
                
                SectionText(title: "4. User Responsibilities") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("4.1. You are solely responsible for the accuracy of property information, iCal URLs, and booking data entered into the App.")
                        Text("4.2. You agree to use the App only for lawful purposes and in accordance with these Terms.")
                        Text("4.3. You agree not to use the App in any way that could damage, disable, overburden, or impair the App or interfere with any other party's use of the App.")
                        Text("4.4. You are responsible for obtaining and maintaining all equipment and services needed for access to and use of the App.")
                    }
                }
                
                SectionText(title: "5. Third-Party Services") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("5.1. The App integrates with third-party services (AirBnB, VRBO, Booking.com) via iCal feeds. We are not responsible for the availability, accuracy, or reliability of these third-party services.")
                        Text("5.2. Your use of third-party services is subject to their respective terms of service and privacy policies.")
                        Text("5.3. We do not endorse, warrant, or assume responsibility for any third-party services or content.")
                    }
                }
                
                SectionText(title: "6. Intellectual Property") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("6.1. The App and its original content, features, and functionality are owned by BnBShift and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.")
                        Text("6.2. You may not copy, modify, distribute, sell, or lease any part of the App without our prior written consent.")
                        Text("6.3. The BnBShift name and logo are trademarks of BnBShift. You may not use these marks without our prior written permission.")
                    }
                }
                
                SectionText(title: "7. Data and Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7.1. Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference.")
                        Text("7.2. You retain all rights to your property data, booking information, and other content you input into the App.")
                        Text("7.3. We collect and use data as described in our Privacy Policy to provide and improve the App.")
                    }
                }
                
                SectionText(title: "8. Disclaimer of Warranties") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("8.1. THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED.")
                        Text("8.2. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.")
                        Text("8.3. WE DO NOT WARRANT THE ACCURACY, COMPLETENESS, OR RELIABILITY OF ANY BOOKING DATA, CALENDAR INFORMATION, OR OTHER CONTENT.")
                        Text("8.4. YOU USE THE APP AT YOUR OWN RISK.")
                    }
                    .font(.caption)
                }
                
                SectionText(title: "9. Limitation of Liability") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("9.1. TO THE MAXIMUM EXTENT PERMITTED BY LAW, BNBSHIFT SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES.")
                        Text("9.2. IN NO EVENT SHALL OUR TOTAL LIABILITY TO YOU FOR ALL DAMAGES EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM.")
                        Text("9.3. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF CERTAIN WARRANTIES OR LIMITATIONS OF LIABILITY, SO SOME OF THE ABOVE LIMITATIONS MAY NOT APPLY TO YOU.")
                    }
                    .font(.caption)
                }
                
                SectionText(title: "10. Indemnification") {
                    Text("You agree to indemnify, defend, and hold harmless BnBShift, its officers, directors, employees, and agents from any claims, liabilities, damages, losses, and expenses, including reasonable attorneys' fees, arising out of or in any way connected with your use of the App or violation of these Terms.")
                }
                
                SectionText(title: "11. Termination") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("11.1. We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason, including breach of these Terms.")
                        Text("11.2. Upon termination, your right to use the App will immediately cease.")
                        Text("11.3. You may terminate your use of the App at any time by deleting the App from your device.")
                    }
                }
                
                SectionText(title: "12. Changes to Terms") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("12.1. We reserve the right to modify these Terms at any time.")
                        Text("12.2. We will notify you of any material changes by updating the \"Last Updated\" date at the top of these Terms.")
                        Text("12.3. Your continued use of the App after changes are posted constitutes acceptance of the modified Terms.")
                    }
                }
                
                SectionText(title: "13. Governing Law") {
                    Text("These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to its conflict of law provisions. Any disputes arising from these Terms or your use of the App shall be subject to the exclusive jurisdiction of the courts located in the United States.")
                }
                
                SectionText(title: "14. Apple App Store Terms") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("14.1. These Terms are between you and BnBShift only, not with Apple Inc. (\"Apple\").")
                        Text("14.2. Apple has no obligation to furnish maintenance and support services with respect to the App.")
                        Text("14.3. In the event of any failure of the App to conform to any applicable warranty, you may notify Apple, and Apple will refund the purchase price (if any) for the App. To the maximum extent permitted by law, Apple will have no other warranty obligation with respect to the App.")
                        Text("14.4. Apple is not responsible for addressing any claims you have or any claims of any third party relating to the App or your possession and use of the App.")
                        Text("14.5. Apple and Apple's subsidiaries are third-party beneficiaries of these Terms, and upon your acceptance of these Terms, Apple will have the right to enforce these Terms against you as a third-party beneficiary.")
                    }
                }
                
                SectionText(title: "15. Severability") {
                    Text("If any provision of these Terms is held to be invalid or unenforceable, such provision shall be struck and the remaining provisions shall be enforced to the fullest extent under law.")
                }
                
                SectionText(title: "16. Entire Agreement") {
                    Text("These Terms, together with our Privacy Policy, constitute the entire agreement between you and BnBShift regarding the use of the App and supersede all prior agreements and understandings.")
                }
                
                SectionText(title: "17. Contact Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you have any questions about these Terms, please contact us at:")
                        Text("Email: support@bnbshift.com")
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("By using BnBShift, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.bottom, 32)
            }
            .padding(20)
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper view for consistent section formatting
struct SectionText<Content: View>: View {
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

#Preview {
    NavigationView {
        TermsOfServiceView()
    }
}
