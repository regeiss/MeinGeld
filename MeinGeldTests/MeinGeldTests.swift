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
