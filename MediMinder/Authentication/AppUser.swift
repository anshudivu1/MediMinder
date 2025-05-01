import Foundation
import FirebaseFirestore

struct AppUser: Codable {
    var id: String // Using String to directly use Firebase UID
    var email: String
    var name: String
    var password: String?
    var age: Int?
    var gender: String?
    var medicalConditions: [String]
    var breakfastTime: Date?
    var lunchTime: Date?
    var dinnerTime: Date?
    var bedtime: Date?
    
    // CodingKeys for Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, email, name, password, age, gender, medicalConditions
        case breakfastTime, lunchTime, dinnerTime, bedtime
    }
    
    init(id: String,
         email: String,
         name: String,
         password: String? = nil,
         age: Int? = nil,
         gender: String? = nil,
         medicalConditions: [String] = [],
         breakfastTime: Date? = nil,
         lunchTime: Date? = nil,
         dinnerTime: Date? = nil,
         bedtime: Date? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.password = password
        self.age = age
        self.gender = gender
        self.medicalConditions = medicalConditions
        self.breakfastTime = breakfastTime
        self.lunchTime = lunchTime
        self.dinnerTime = dinnerTime
        self.bedtime = bedtime
    }
}

enum AuthError: Error {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case userNotFound
    case wrongPassword
    case passwordsDontMatch
    case resetEmailSent
    case accountDeleted
    case requiresReauthentication
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
        case .resetEmailSent: return "Password reset email sent"
        case .accountDeleted: return "Account successfully deleted"
        case .requiresReauthentication: return "Please re-enter your credentials to delete your account"
        }
    }
}
