//
//  ForgotPasswordView.swift
//  MediMinder
//
//  Created by SuperCharge on 30/04/25.
//


import SwiftUI

struct ForgotPasswordView: View {
    @Binding var isShowingForgotPassword: Bool
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var isAnimating = false
    @State private var showSuccessMessage = false
    
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
                
                Image(systemName: "key.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
            }
            .onAppear {
                isAnimating = true
            }
            
            Text("Password Reset")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            
            if showSuccessMessage {
                Text("Password reset link sent to your email")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            } else {
                Text("Enter your email to receive a password reset link")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
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
                        .disableAutocorrection(true)
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
            
            // Reset password button
            Button(action: sendPasswordReset) {
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
                        Text("Send Reset Link")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(email.isEmpty || authService.isLoading)
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Back to sign in button
            Button {
                withAnimation {
                    isShowingForgotPassword = false
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Remember your password?")
                        .foregroundColor(.gray)
                    Text("Sign In")
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
    
    private func sendPasswordReset() {
        Task {
            await authService.resetPassword(email: email)
            showSuccessMessage = true
        }
    }
}