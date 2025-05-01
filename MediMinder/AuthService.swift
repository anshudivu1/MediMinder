import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var error: AuthError?
    @Published var isProfileCompleted = false
    
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "currentUserKey"
    
    init() {
        setupAuthStateHandler()
        loadCurrentUser()
    }
    
    private func setupAuthStateHandler() {
        // Monitor auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                // User is signed in
                self.fetchUserProfile(userId: user.uid)
            } else {
                // User is signed out
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.isProfileCompleted = false
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        self.isLoading = true
        self.error = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                    let nsError = error as NSError
                    let errorCode = AuthErrorCode(_bridgedNSError: nsError)?.code
                    
                    switch errorCode {
                    case .userNotFound:
                        self.error = .userNotFound
                    case .wrongPassword:
                        self.error = .wrongPassword
                    default:
                        self.error = .invalidCredentials
                    }
                    return
                }
                
                if let userId = authResult?.user.uid {
                    self.fetchUserProfile(userId: userId)
                }
            }
        }
    }
    
    func signUp(email: String, name: String, password: String, confirmPassword: String) {
        self.isLoading = true
        self.error = nil
        
        // Validate password match
        if password != confirmPassword {
            self.isLoading = false
            self.error = .passwordsDontMatch
            return
        }
        
        // Validate password strength
        if password.count < 6 {
            self.isLoading = false
            self.error = .weakPassword
            return
        }
        
        // Create user in Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Firebase signup error: \(error.localizedDescription)")
                    let nsError = error as NSError
                    let errorCode = AuthErrorCode(_bridgedNSError: nsError)?.code
                    
                    switch errorCode {
                    case .emailAlreadyInUse:
                        self.error = .emailAlreadyInUse
                    case .weakPassword:
                        self.error = .weakPassword
                    default:
                        self.error = .invalidCredentials
                    }
                    
                    self.isLoading = false
                    return
                }
                
                if let userId = authResult?.user.uid {
                    // Create user profile in Firestore
                    let newUser = AppUser(
                        id: userId,  // Use Firebase UID string directly
                        email: email,
                        name: name,
                        password: ""  // We don't store the password in Firestore
                    )
                    
                    self.createUserProfile(user: newUser, userId: userId)
                }
            }
        }
    }
    
    func resetPassword(email: String) async {
        self.isLoading = true
        self.error = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Password reset error: \(error.localizedDescription)")
                let nsError = error as NSError
                let errorCode = AuthErrorCode(_bridgedNSError: nsError)?.code
                
                switch errorCode {
                case .userNotFound:
                    self.error = .userNotFound
                default:
                    self.error = .invalidCredentials
                }
            }
        }
    }
    
    func deleteAccount() async {
        self.isLoading = true
        self.error = nil
        
        guard let user = Auth.auth().currentUser, let userId = currentUser?.id else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = .userNotFound
            }
            return
        }
        
        // Delete from Firestore first
        do {
            try await db.collection("users").document(userId).delete()
            
            // Then delete the Firebase Auth account
            try await user.delete()
            
            // Clear local storage
            DispatchQueue.main.async {
                self.deleteCurrentUser()
                self.userDefaults.removeObject(forKey: "userProfile")
                self.currentUser = nil
                self.isAuthenticated = false
                self.isProfileCompleted = false
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                print("Account deletion error: \(error.localizedDescription)")
                self.error = .invalidCredentials
            }
        }
    }
    
    func completeProfile(age: Int, gender: String, medicalConditions: [String],
                         breakfastTime: Date, lunchTime: Date, dinnerTime: Date, bedtime: Date) {
        guard var user = currentUser, let authUser = Auth.auth().currentUser else { return }
        
        user.age = age
        user.gender = gender
        user.medicalConditions = medicalConditions
        
        // Store the complete date objects - they will be properly converted to Timestamps in Firestore
        user.breakfastTime = breakfastTime
        user.lunchTime = lunchTime
        user.dinnerTime = dinnerTime
        user.bedtime = bedtime
        
        let userId = authUser.uid
        
        // Update the user profile in Firestore
        updateUserProfile(user: user, userId: userId)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            deleteCurrentUser()
            userDefaults.removeObject(forKey: "userProfile")
            
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isProfileCompleted = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    
    private func createUserProfile(user: AppUser, userId: String) {
        let userRef = db.collection("users").document(userId)
        
        // Convert dates to timestamps for Firestore
        var userData: [String: Any] = [
            "id": user.id,  // Store the string ID directly
            "email": user.email,
            "name": user.name,
            "medicalConditions": user.medicalConditions
        ]
        
        if let age = user.age {
            userData["age"] = age
        }
        
        if let gender = user.gender {
            userData["gender"] = gender
        }
        
        // Store time fields as Timestamps if available
        if let breakfastTime = user.breakfastTime {
            userData["breakfastTime"] = Timestamp(date: breakfastTime)
        }
        
        if let lunchTime = user.lunchTime {
            userData["lunchTime"] = Timestamp(date: lunchTime)
        }
        
        if let dinnerTime = user.dinnerTime {
            userData["dinnerTime"] = Timestamp(date: dinnerTime)
        }
        
        if let bedtime = user.bedtime {
            userData["bedtime"] = Timestamp(date: bedtime)
        }
        
        userRef.setData(userData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error creating user profile: \(error.localizedDescription)")
                    self.error = .invalidCredentials
                    return
                }
                
                self.currentUser = user
                self.isAuthenticated = true
                self.isProfileCompleted = false
                self.saveCurrentUser(user)
                self.syncUserProfileWithProfileView()
            }
        }
    }
    
    private func updateUserProfile(user: AppUser, userId: String) {
        let userRef = db.collection("users").document(userId)
        
        var userData: [String: Any] = [:]
        
        if let age = user.age {
            userData["age"] = age
        }
        
        if let gender = user.gender {
            userData["gender"] = gender
        }
        
        userData["medicalConditions"] = user.medicalConditions
        
        // Store time fields as Timestamps
        if let breakfastTime = user.breakfastTime {
            userData["breakfastTime"] = Timestamp(date: breakfastTime)
        }
        
        if let lunchTime = user.lunchTime {
            userData["lunchTime"] = Timestamp(date: lunchTime)
        }
        
        if let dinnerTime = user.dinnerTime {
            userData["dinnerTime"] = Timestamp(date: dinnerTime)
        }
        
        if let bedtime = user.bedtime {
            userData["bedtime"] = Timestamp(date: bedtime)
        }
        
        userRef.updateData(userData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating user profile: \(error.localizedDescription)")
                    return
                }
                
                self.currentUser = user
                self.isProfileCompleted = true
                self.saveCurrentUser(user)
                self.syncUserProfileWithProfileView()
            }
        }
    }
    
    private func fetchUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching user profile: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    print("User document does not exist")
                    return
                }
                
                // Extract data from Firestore document
                let id = data["id"] as? String ?? userId
                let email = data["email"] as? String ?? ""
                let name = data["name"] as? String ?? ""
                let age = data["age"] as? Int
                let gender = data["gender"] as? String
                let medicalConditions = data["medicalConditions"] as? [String] ?? []
                
                // Convert Firestore Timestamps to Date objects
                let breakfastTime = (data["breakfastTime"] as? Timestamp)?.dateValue()
                let lunchTime = (data["lunchTime"] as? Timestamp)?.dateValue()
                let dinnerTime = (data["dinnerTime"] as? Timestamp)?.dateValue()
                let bedtime = (data["bedtime"] as? Timestamp)?.dateValue()
                
                // Create AppUser object
                let user = AppUser(
                    id: id,
                    email: email,
                    name: name,
                    password: "",  // We don't store the password in Firestore
                    age: age,
                    gender: gender,
                    medicalConditions: medicalConditions,
                    breakfastTime: breakfastTime,
                    lunchTime: lunchTime,
                    dinnerTime: dinnerTime,
                    bedtime: bedtime
                )
                
                // Update the app state
                self.currentUser = user
                self.isAuthenticated = true
                self.isProfileCompleted = self.isUserProfileComplete(user)
                self.saveCurrentUser(user)
                self.syncUserProfileWithProfileView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func syncUserProfileWithProfileView() {
        guard let currentUser = currentUser else { return }
        
        // Create a User object from AppUser
        let profileUser = User(from: currentUser)
        
        // Save to UserDefaults in the format expected by ProfileView
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(profileUser) {
            userDefaults.set(encoded, forKey: "userProfile")
        }
    }
    
    private func saveCurrentUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: currentUserKey)
        }
    }
    
    private func deleteCurrentUser() {
        userDefaults.removeObject(forKey: currentUserKey)
    }
    
    private func loadCurrentUser() {
        guard let data = userDefaults.data(forKey: currentUserKey) else { return }
        
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
            print("Error loading current user: \(error.localizedDescription)")
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
    
    // For debugging purposes
    func clearAllUsers() {
        deleteCurrentUser()
        userDefaults.removeObject(forKey: "userProfile")
        
        // Sign out of Firebase Auth
        try? Auth.auth().signOut()
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
            self.isProfileCompleted = false
        }
    }
}
