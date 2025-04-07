//
//  AuthenticationView.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingSignUp = false
    @EnvironmentObject private var authService: AuthService
    @State private var authState: AuthState = .unauthenticated
    @State private var animateBackground = false
    
    enum AuthState {
        case unauthenticated
        case profileCompletion
        case authenticated
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateBackground)
            .onAppear {
                animateBackground = true
            }
            
            // Bubble pattern overlay
            BubblePattern()
            
            // Main content
            Group {
                switch authState {
                case .unauthenticated:
                    NavigationStack {
                        if isShowingSignUp {
                            SignUpView(isShowingSignUp: $isShowingSignUp)
                                .environmentObject(authService)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        } else {
                            SignInView(isShowingSignUp: $isShowingSignUp)
                                .environmentObject(authService)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                    
                case .profileCompletion:
                    NavigationStack {
                        ProfileCompletionView(onComplete: {
                            // Transition to authenticated state when profile is completed
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                authState = .authenticated
                            }
                        })
                        .environmentObject(authService)
                    }
                    
                case .authenticated:
                    ContentView()
                        .environmentObject(authService)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShowingSignUp)
        }
        .onAppear {
            // Determine initial state when view appears
            updateAuthState()
        }
        .onChange(of: authService.isAuthenticated) { _ in
            updateAuthState()
        }
        .onChange(of: authService.isProfileCompleted) { _ in
            updateAuthState()
        }
    }
    
    private func updateAuthState() {
        if authService.isAuthenticated {
            if authService.isProfileCompleted {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    authState = .authenticated
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    authState = .profileCompletion
                }
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                authState = .unauthenticated
            }
        }
    }
}

// Decorative bubble pattern view
struct BubblePattern: View {
    var body: some View {
        ZStack {
            ForEach(0..<20) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.05...0.15)))
                    .frame(width: CGFloat.random(in: 20...120))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.interpolatingSpring(stiffness: 0.3, damping: 0.8)
                            .repeatForever()
                            .delay(Double.random(in: 0...5)),
                        value: UUID()
                    )
            }
        }
        .drawingGroup() // Optimize rendering
    }
}
