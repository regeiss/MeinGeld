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
  var category: String  // Manter como String para compatibilidade com SwiftData
  var limit: Decimal
  var spent: Decimal
  var month: Int
  var year: Int
  var user: User?

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
    self.category = category.rawValue  // Armazena como String
    self.limit = limit
    self.spent = spent
    self.month = month
    self.year = year
    self.user = user
  }
}

// MARK: - Helper Extensions
extension Budget {
  // Propriedade computada para obter o enum
  var categoryEnum: TransactionCategory {
    return TransactionCategory(rawValue: category) ?? .other
  }

  // Método para atualizar a categoria
  func updateCategory(_ newCategory: TransactionCategory) {
    self.category = newCategory.rawValue
  }

  // Propriedades de conveniência
  var categoryDisplayName: String {
    return categoryEnum.displayName
  }

  var categoryIconName: String {
    return categoryEnum.iconName
  }
}
