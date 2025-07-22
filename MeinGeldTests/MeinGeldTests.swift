//
//  MeinGeldTests.swift
//  MeinGeldTests
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftData
import Testing

@testable import MeinGeld

// Mock do Firebase Service
final class MockFirebaseService: FirebaseServiceProtocol {
  var eventsLogged: [AnalyticsEvent] = []
  var errorsRecorded: [Error] = []

  func configure() {}

  func logEvent(_ event: AnalyticsEvent) {
    eventsLogged.append(event)
  }

  func recordError(_ error: Error, context: String) {
    errorsRecorded.append(error)
  }

  func recordNonFatalError(_ error: Error, context: String) {
    errorsRecorded.append(error)
  }

  func setUserID(_ userID: String) {}
  func setUserProperty(_ value: String?, forName name: String) {}
}

// Mock do Error Manager
final class MockErrorManager: ErrorManagerProtocol {
  var handledErrors: [(Error, String)] = []
  var warnings: [(String, String)] = []
  var infos: [(String, String)] = []

  func handle(_ error: Error, context: String) {
    handledErrors.append((error, context))
  }

  func handleNonFatal(_ error: Error, context: String) {
    handledErrors.append((error, context))
  }

  func logWarning(_ message: String, context: String) {
    warnings.append((message, context))
  }

  func logInfo(_ message: String, context: String) {
    infos.append((message, context))
  }
}

// Testes para AuthenticationManager
@MainActor

// Test Helper Extensions
extension User {
  static func mock(
    email: String = "test@example.com",
    name: String = "Test User"
  ) -> User {
    User(email: email, name: name)
  }
}

extension Transaction {
  static func mock(
    amount: Decimal = 100,
    description: String = "Test Transaction",
    category: TransactionCategory = .other,
    type: TransactionType = .expense
  ) -> Transaction {
    Transaction(
      amount: amount,
      description: description,
      date: Date(),
      category: category,
      type: type
    )
  }
}

