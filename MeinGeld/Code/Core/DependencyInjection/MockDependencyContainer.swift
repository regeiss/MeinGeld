//
//  MockDependencyContainer.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//
import Foundation
import SwiftData
import SwiftUI
import Combine

final class MockDependencyContainer: DependencyContainer {

  lazy var errorManager: ErrorManagerProtocol = MockErrorManager()
  lazy var firebaseService: FirebaseServiceProtocol = MockFirebaseService()
  lazy var themeManager: ThemeManager = ThemeManager.shared
  lazy var dataService: DataServiceProtocol = MockDataService()

  lazy var authManager: any AuthenticationManagerProtocol = {
    let manager = MockAuthenticationManager()
    return manager
  }()

  init() {
    // Setup mock data if needed
    Task {
      try? await dataService.generateSampleData()
    }
  }
}

// MARK: - Mock Authentication Manager for Testing
@MainActor
final class MockAuthenticationManager: @MainActor AuthenticationManagerProtocol {
  var objectWillChange: ObservableObjectPublisher
  
  var currentUser: User?
  var isAuthenticated: Bool { currentUser != nil }
  var isLoading = false
  var errorMessage: String?

  init() {
    self.objectWillChange = ObservableObjectPublisher()
    self.currentUser = nil
    self.isLoading = false
    self.errorMessage = nil
  }

  func setModelContext(_ context: ModelContext) {
    // Mock implementation
  }

  func signIn(email: String, password: String) async throws {
    isLoading = true
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

    currentUser = User(email: email, name: "Mock User")
    isLoading = false
  }

  func signUp(name: String, email: String, password: String) async throws {
    isLoading = true
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

    currentUser = User(email: email, name: name)
    isLoading = false
  }

  func signOut() {
    currentUser = nil
  }

  func resetPassword(email: String) async throws {
    try await Task.sleep(nanoseconds: 200_000_000)  // 0.2 seconds
  }

  func updateProfile(name: String, profileImageData: Data?) async throws {
    try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds
    currentUser?.name = name
    if let imageData = profileImageData {
      currentUser?.profileImageData = imageData
    }
  }

  func deleteAccount() async throws {
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
    currentUser = nil
  }
}
