//
//  SignInView.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//

import SwiftUI

struct SignInView: View {
    @Binding var isShowingSignUp: Bool
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Logo animation
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 110, height: 110)
                
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                    .frame(width: 130, height: 130)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "pill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }
            .onAppear {
                isAnimating = true
            }
            
            Text("MediMinder")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            
            Text("Welcome Back")
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                // Email field
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    TextField("", text: $email)
                        .placeholder(when: email.isEmpty) {
                            Text("Email").foregroundColor(.gray)
                        }
                        .foregroundColor(.primary)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
                
                // Password field
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    if showPassword {
                        TextField("", text: $password)
                            .placeholder(when: password.isEmpty) {
                                Text("Password").foregroundColor(.gray)
                            }
                            .foregroundColor(.primary)
                    } else {
                        SecureField("", text: $password)
                            .placeholder(when: password.isEmpty) {
                                Text("Password").foregroundColor(.gray)
                            }
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            .padding(.horizontal, 30)
            
            if let error = authService.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.top, 5)
            }
            
            // Sign in button
            Button(action: signIn) {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 55)
                        .shadow(color: Color.blue.opacity(0.2), radius: 5, x: 0, y: 3)
                    
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Sign up link
            Button {
                withAnimation {
                    isShowingSignUp = true
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .font(.system(size: 16))
            }
            .padding(.top, 15)
            
            Spacer()
        }
        .background(Color.white)
    }
    
    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
        }
    }
}

// Helper extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// Error localization extension
extension AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password"
        case .emailAlreadyInUse: return "Email already in use"
        case .weakPassword: return "Password must be at least 6 characters"
        case .userNotFound: return "User not found"
        case .wrongPassword: return "Wrong password"
        case .passwordsDontMatch: return "Passwords don't match"
        }
    }
}
