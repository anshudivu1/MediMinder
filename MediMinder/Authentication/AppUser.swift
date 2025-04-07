//
//  AppUser.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//


import Foundation

struct AppUser: Codable {
    let id: UUID
    var email: String
    var name: String
    var password: String
    var age: Int?
    var gender: String?
    var medicalConditions: [String]
    var breakfastTime: Date?
    var lunchTime: Date?
    var dinnerTime: Date?
    var bedtime: Date?
    
    init(id: UUID = UUID(),
         email: String,
         name: String,
         password: String,
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
}
