//
//  Budget.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 13/07/25.
//
import Foundation
import SwiftData

@Model
final class Budget {
  var id: UUID
  var categoryRawValue: String  // Armazena como String para SwiftData
  var limit: Decimal
  var spent: Decimal
  var month: Int
  var year: Int
  var user: User?

  // Computed property para acessar como enum
  var category: TransactionCategory {
    get {
      return TransactionCategory(rawValue: categoryRawValue) ?? .other
    }
    set {
      categoryRawValue = newValue.rawValue
    }
  }

  init(
    id: UUID = UUID(),
    category: TransactionCategory,
    limit: Decimal,
    spent: Decimal = 0,
    month: Int,
    year: Int,
    user: User? = nil
  ) {
    self.id = id
    self.categoryRawValue = category.rawValue
    self.limit = limit
    self.spent = spent
    self.month = month
    self.year = year
    self.user = user
  }
}

// MARK: - Migration Helper
// Se você já tem dados, pode precisar migrar

extension Budget {
  // Helper para buscar por categoria (se necessário)
  static func predicate(for category: TransactionCategory) -> Predicate<Budget>
  {
    let categoryRaw = category.rawValue
    return #Predicate<Budget> { budget in
      budget.categoryRawValue == categoryRaw
    }
  }
}
