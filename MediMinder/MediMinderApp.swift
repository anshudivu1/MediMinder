//
//  MediMinderApp.swift
//  MediMinder
//
//  Created by Divyanshu Sharma on 04/04/25.
//

import SwiftUI
import UserNotifications

@main
struct MediMinderApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authService)
                .onAppear {
                    // Request notification permissions when the app starts
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        if granted {
                            print("Notification permission granted")
                        } else if let error = error {
                            print("Notification permission denied: \(error.localizedDescription)")
                        }
                     }
                }
        }
    }
}
