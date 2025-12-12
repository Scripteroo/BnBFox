//
//  LoadingView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var bubbles: [Bubble] = []
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated turtle logo with bubbles
                ZStack {
                    // Bubbles
                    ForEach(bubbles) { bubble in
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: bubble.size, height: bubble.size)
                            .position(x: bubble.x, y: bubble.y)
                    }
                    
                    // Turtle logo with swimming animation
                    Image("KawamaLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(isAnimating ? 3 : -3))
                        .offset(y: isAnimating ? -10 : 10)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .frame(height: 250)
                
                // Loading text
                VStack(spacing: 12) {
                    Text("Loading Kawama Calendar")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Fetching booking data...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // Progress indicator
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding(.top, 8)
                }
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            startBubbleAnimation()
        }
    }
    
    private func startBubbleAnimation() {
        // Create initial bubbles
        for _ in 0..<8 {
            addBubble()
        }
        
        // Continuously add new bubbles
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            addBubble()
            removeOldBubbles()
        }
    }
    
    private func addBubble() {
        let bubble = Bubble(
            x: CGFloat.random(in: 100...300),
            y: 300,
            size: CGFloat.random(in: 8...20)
        )
        
        withAnimation(.linear(duration: Double.random(in: 3...5))) {
            bubbles.append(bubble)
            if let index = bubbles.firstIndex(where: { $0.id == bubble.id }) {
                bubbles[index].y = -50
            }
        }
    }
    
    private func removeOldBubbles() {
        bubbles.removeAll { $0.y < 0 }
    }
}

struct Bubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
}

#Preview {
    LoadingView()
}
