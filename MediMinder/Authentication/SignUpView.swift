//
//  SignUpView.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//
//
//  SignUpView.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//

import SwiftUI

struct SignUpView: View {
    @Binding var isShowingSignUp: Bool
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Logo with pulse animation
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
            
            Text("Create Account")
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.bottom, 5)
            
            ScrollView {
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
                    
                    // Name field
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        TextField("", text: $name)
                            .placeholder(when: name.isEmpty) {
                                Text("Full Name").foregroundColor(.gray)
                            }
                            .foregroundColor(.primary)
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
                    
                    // Confirm Password field
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        if showConfirmPassword {
                            TextField("", text: $confirmPassword)
                                .placeholder(when: confirmPassword.isEmpty) {
                                    Text("Confirm Password").foregroundColor(.gray)
                                }
                                .foregroundColor(.primary)
                        } else {
                            SecureField("", text: $confirmPassword)
                                .placeholder(when: confirmPassword.isEmpty) {
                                    Text("Confirm Password").foregroundColor(.gray)
                                }
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
                
                // Error message
                if let error = authService.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                        .padding(.top, 5)
                }
                
                // Password strength indicator
                if !password.isEmpty {
                    PasswordStrengthView(password: password)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                }
                
                // Sign up button
                Button(action: signUp) {
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
                            Text("Sign Up")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Sign in link
                Button {
                    withAnimation {
                        isShowingSignUp = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .font(.system(size: 16))
                }
                .padding(.top, 15)
                .padding(.bottom, 30)
            }
        }
        .background(Color.white)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !name.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() {
        Task {
            await authService.signUp(
                email: email,
                name: name,
                password: password,
                confirmPassword: confirmPassword
            )
        }
    }
}

// Password strength indicator
struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 10 {
            return .medium
        } else {
            return .strong
        }
    }
    
    private enum PasswordStrength {
        case weak, medium, strong
        
        var color: Color {
            switch self {
            case .weak: return .red
            case .medium: return .yellow
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password Strength:")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text(strength.text)
                    .foregroundColor(strength.color)
                    .font(.caption.bold())
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(strength.color)
                    .frame(width: strengthBarWidth(), height: 4)
                    .cornerRadius(2)
            }
        }
    }
    
    private func strengthBarWidth() -> CGFloat {
        switch strength {
        case .weak: return UIScreen.main.bounds.width * 0.2
        case .medium: return UIScreen.main.bounds.width * 0.4
        case .strong: return UIScreen.main.bounds.width * 0.6
        }
    }
}
