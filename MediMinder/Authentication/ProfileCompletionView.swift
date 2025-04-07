//
//  ProfileCompletionView.swift
//  MediMinder
//
//  Created by Apple23 on 04/04/25.
//

import SwiftUI

struct ProfileCompletionView: View {
    @EnvironmentObject var authService: AuthService
    var onComplete: () -> Void
    
    @State private var age: Int = 30
    @State private var gender = "Male"
    @State private var medicalConditions: [String] = []
    @State private var newCondition = ""
    @State private var breakfastTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var lunchTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!
    @State private var dinnerTime = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!
    @State private var isSaving = false
    @FocusState private var isConditionFieldFocused: Bool
    
    let genders = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Tell us about yourself for a personalized experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top)
                    
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Age Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Age")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(age)")
                                    .fontWeight(.semibold)
                            }
                            
                            Slider(value: Binding(
                                get: { Double(age) },
                                set: { age = Int($0) }
                            ), in: 1...120, step: 1)
                            .tint(.blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        
                        // Gender Picker
                        Menu {
                            ForEach(genders, id: \.self) { genderOption in
                                Button(genderOption) {
                                    gender = genderOption
                                }
                            }
                        } label: {
                            HStack {
                                Text("Gender")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(gender)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    // Medical Conditions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Medical Conditions")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Optional - Add any relevant health conditions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Add condition field
                        HStack {
                            TextField("Add condition", text: $newCondition)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .focused($isConditionFieldFocused)
                            
                            Button(action: addCondition) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .disabled(newCondition.isEmpty)
                        }
                        
                        // Conditions list
                        if !medicalConditions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(medicalConditions.indices, id: \.self) { index in
                                    HStack {
                                        Text(medicalConditions[index])
                                        Spacer()
                                        Button {
                                            deleteCondition(at: IndexSet(integer: index))
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }
                    
                    // Daily Schedule
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Schedule")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        timePickerView(title: "Breakfast", time: $breakfastTime)
                        timePickerView(title: "Lunch", time: $lunchTime)
                        timePickerView(title: "Dinner", time: $dinnerTime)
                        timePickerView(title: "Bedtime", time: $bedtime)
                    }
                    
                    // Save Button
                    Button {
                        saveProfile()
                    } label: {
                        Text("Complete Profile")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.vertical)
                    
                    // Skip button
                    Button {
                        saveProfile()
                    } label: {
                        Text("Skip for now")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom)
                }
                .padding(.horizontal)
            }
            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        saveProfile()
                    } label: {
                        Text("Skip")
                            .foregroundColor(.secondary)
                    }
                    .disabled(isSaving)
                }
            }
            
            // Loading overlay
            if isSaving {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.blue)
                            
                            Text("Saving...")
                                .foregroundColor(.primary)
                                .padding(.top)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 10)
                        )
                    }
            }
        }
        .onAppear {
            if let currentUser = authService.currentUser {
                if let age = currentUser.age {
                    self.age = age
                }
                if let gender = currentUser.gender {
                    self.gender = gender
                }
                self.medicalConditions = currentUser.medicalConditions
                if let breakfastTime = currentUser.breakfastTime {
                    self.breakfastTime = breakfastTime
                }
                if let lunchTime = currentUser.lunchTime {
                    self.lunchTime = lunchTime
                }
                if let dinnerTime = currentUser.dinnerTime {
                    self.dinnerTime = dinnerTime
                }
                if let bedtime = currentUser.bedtime {
                    self.bedtime = bedtime
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // Helper function for time pickers
    private func timePickerView(title: String, time: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func addCondition() {
        guard !newCondition.isEmpty else { return }
        
        withAnimation {
            medicalConditions.append(newCondition)
            newCondition = ""
        }
        isConditionFieldFocused = false
    }
    
    private func deleteCondition(at offsets: IndexSet) {
        withAnimation {
            medicalConditions.remove(atOffsets: offsets)
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        // Save the profile data
        authService.completeProfile(
            age: age,
            gender: gender,
            medicalConditions: medicalConditions,
            breakfastTime: breakfastTime,
            lunchTime: lunchTime,
            dinnerTime: dinnerTime,
            bedtime: bedtime
        )
        
        // Wait a short delay to ensure data is saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            onComplete() // Call the completion handler to trigger the transition
        }
    }
}
