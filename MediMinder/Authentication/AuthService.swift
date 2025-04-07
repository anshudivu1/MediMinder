//
//  AuthService.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//

import Foundation
import Security
import CryptoKit

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var error: AuthError?
    @Published var isProfileCompleted = false
    
    private let usersKey = "mediminderUsersKey"
    private let currentUserKey = "currentUserKey"
    
    init() {
        loadCurrentUser()
    }
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let users = loadAllUsers()
            guard let user = users.first(where: { $0.email.lowercased() == email.lowercased() }) else {
                throw AuthError.userNotFound
            }
            
            guard user.password == password else {
                throw AuthError.wrongPassword
            }
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.isProfileCompleted = self.isUserProfileComplete(user)
                self.isLoading = false
                self.saveCurrentUser(user)
                
                // Sync with ProfileView
                self.syncUserProfileWithProfileView()
            }
            
        } catch let error as AuthError {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .wrongPassword
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, name: String, password: String, confirmPassword: String) async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            guard password == confirmPassword else {
                throw AuthError.passwordsDontMatch
            }
            
            guard password.count >= 6 else {
                throw AuthError.weakPassword
            }
            
            // Normalize the email for case-insensitive comparison
            let normalizedEmail = email.lowercased()
            
            var users = loadAllUsers()
            
            // Check if email already exists (case insensitive)
            if users.contains(where: { $0.email.lowercased() == normalizedEmail }) {
                throw AuthError.emailAlreadyInUse
            }
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let newUser = AppUser(email: email, name: name, password: password)
            users.append(newUser)
            saveAllUsers(users)
            
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
                self.isProfileCompleted = false
                self.isLoading = false
                
                // Save the current user securely
                self.saveCurrentUser(newUser)
                
                // Even though the profile is not complete, sync the available data
                // This ensures that name is available in ProfileView
                self.syncUserProfileWithProfileView()
            }
        } catch let error as AuthError {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .invalidCredentials
                self.isLoading = false
            }
        }
    }
    
    func completeProfile(age: Int, gender: String, medicalConditions: [String],
                       breakfastTime: Date, lunchTime: Date, dinnerTime: Date, bedtime: Date) {
        guard var user = currentUser else { return }
        
        user.age = age
        user.gender = gender
        user.medicalConditions = medicalConditions
        user.breakfastTime = breakfastTime
        user.lunchTime = lunchTime
        user.dinnerTime = dinnerTime
        user.bedtime = bedtime
        
        var users = loadAllUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveAllUsers(users)
            
            // Update the current user
            saveCurrentUser(user)
            
            // Explicitly create and sync a User object to ProfileView
            syncUserProfileWithProfileView()
            
            // Update published properties
            DispatchQueue.main.async {
                self.currentUser = user
                self.isProfileCompleted = true
            }
        }
    }
    
    func signOut() {
        deleteCurrentUser()
        
        // Also clear the UserProfile used by ProfileView
        UserDefaults.standard.removeObject(forKey: "userProfile")
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
            self.isProfileCompleted = false
        }
    }
    
    func syncUserProfileWithProfileView() {
        guard let currentUser = currentUser else { return }
        
        // Create a User object from AppUser
        let profileUser = User(from: currentUser)
        
        // Save to UserDefaults in the format expected by ProfileView
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(profileUser) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }

    private func saveCurrentUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        }
    }
    
    private func deleteCurrentUser() {
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    private func loadCurrentUser() {
        guard let data = UserDefaults.standard.data(forKey: currentUserKey) else { return }
        
        do {
            let user = try JSONDecoder().decode(AppUser.self, from: data)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                self.isProfileCompleted = self.isUserProfileComplete(user)
                
                // Ensure that ProfileView is in sync with the loaded user
                self.syncUserProfileWithProfileView()
            }
        } catch {
            print("Error loading current user: \(error)")
            deleteCurrentUser() // Clean up corrupted data
        }
    }
    
    private func isUserProfileComplete(_ user: AppUser) -> Bool {
        return user.age != nil &&
               user.gender != nil &&
               user.breakfastTime != nil &&
               user.lunchTime != nil &&
               user.dinnerTime != nil &&
               user.bedtime != nil
    }
    
    private func loadAllUsers() -> [AppUser] {
        guard let data = UserDefaults.standard.data(forKey: usersKey) else { return [] }
        return (try? JSONDecoder().decode([AppUser].self, from: data)) ?? []
    }
    
    private func saveAllUsers(_ users: [AppUser]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    // For debugging purposes
    func clearAllUsers() {
        UserDefaults.standard.removeObject(forKey: usersKey)
        deleteCurrentUser()
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
            self.isProfileCompleted = false
        }
    }
}
