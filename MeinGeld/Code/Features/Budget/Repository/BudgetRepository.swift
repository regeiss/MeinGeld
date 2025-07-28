//
//  BudgetRepository.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 27/07/25.
//

import Foundation
import SwiftData

protocol BudgetRepositoryProtocol: Sendable {
  func fetchBudgets(for userId: UUID) async throws -> [Budget]
  func fetchBudget(by id: UUID) async throws -> Budget?
  func fetchBudgets(for userId: UUID, month: Int, year: Int) async throws
    -> [Budget]
  func fetchBudget(
    for userId: UUID,
    category: TransactionCategory,
    month: Int,
    year: Int
  ) async throws -> Budget?
  func createBudget(_ budget: Budget) async throws
  func updateBudget(_ budget: Budget) async throws
  func deleteBudget(_ budget: Budget) async throws
  func updateSpentAmount(for budgetId: UUID, newAmount: Decimal) async throws
  func getBudgetSummary(for userId: UUID, month: Int, year: Int) async throws
    -> BudgetSummary
  func checkBudgetLimits(
    for userId: UUID,
    category: TransactionCategory,
    amount: Decimal
  ) async throws -> BudgetAlert?
}

struct BudgetSummary {
  let totalBudgeted: Decimal
  let totalSpent: Decimal
  let totalRemaining: Decimal
  let budgetCount: Int
  let overBudgetCount: Int
  let utilizationPercentage: Double
}

struct BudgetAlert {
  let budget: Budget
  let alertType: BudgetAlertType
  let message: String
}

enum BudgetAlertType {
  case warning  // 80% do limite
  case danger  // 100% do limite
  case exceeded  // Acima de 100%
}

@MainActor
final class BudgetRepository: BudgetRepositoryProtocol {
  private let modelContext: ModelContext
  private let errorManager: ErrorManagerProtocol
  private let firebaseService: FirebaseServiceProtocol

  init(
    modelContext: ModelContext,
    errorManager: ErrorManagerProtocol = ErrorManager.shared,
    firebaseService: FirebaseServiceProtocol = FirebaseService.shared
  ) {
    self.modelContext = modelContext
    self.errorManager = errorManager
    self.firebaseService = firebaseService
  }

  func fetchBudgets(for userId: UUID) async throws -> [Budget] {
    do {
      let capturedUserId = userId
      let descriptor = FetchDescriptor<Budget>(
        predicate: #Predicate<Budget> { budget in budget.user?.id == capturedUserId },
        sortBy: [
          SortDescriptor(\.year, order: .reverse),
          SortDescriptor(\.month, order: .reverse),
          SortDescriptor(\.category),
        ]
      )
      let budgets = try modelContext.fetch(descriptor)

      errorManager.logInfo(
        "Orçamentos carregados: \(budgets.count) para usuário \(userId)",
        context: "BudgetRepository.fetchBudgets"
      )

      return budgets
    } catch {
      errorManager.handle(error, context: "BudgetRepository.fetchBudgets")
      throw AppError.dataNotFound
    }
  }

  func fetchBudget(by id: UUID) async throws -> Budget? {
    do {
      let descriptor = FetchDescriptor<Budget>(
        predicate: #Predicate<Budget> { $0.id == id }
      )
      let budgets = try modelContext.fetch(descriptor)

      return budgets.first
    } catch {
      errorManager.handle(error, context: "BudgetRepository.fetchBudget")
      throw AppError.dataNotFound
    }
  }

  func fetchBudgets(for userId: UUID, month: Int, year: Int) async throws
    -> [Budget]
  {
    do {
      let capturedUserId = userId
      let capturedMonth = month
      let capturedYear = year
      let descriptor = FetchDescriptor<Budget>(
        predicate: #Predicate<Budget> {
          budget in budget.user?.id == capturedUserId && budget.month == capturedMonth && budget.year == capturedYear
        },
        sortBy: [SortDescriptor(\.category)]
      )
      let budgets = try modelContext.fetch(descriptor)

      return budgets
    } catch {
      errorManager.handle(
        error,
        context: "BudgetRepository.fetchBudgets(month:year:)"
      )
      throw AppError.dataNotFound
    }
  }

  func fetchBudget(
    for userId: UUID,
    category: TransactionCategory,
    month: Int,
    year: Int
  ) async throws -> Budget? {
    do {
      let capturedUserId = userId
      let capturedCategoryRaw = category.rawValue
      let capturedMonth = month
      let capturedYear = year
      let descriptor = FetchDescriptor<Budget>(
        predicate: #Predicate<Budget> {
          budget in budget.user?.id == capturedUserId && budget.categoryRawValue == capturedCategoryRaw && budget.month == capturedMonth && budget.year == capturedYear
        }
      )
      let budgets = try modelContext.fetch(descriptor)

      return budgets.first
    } catch {
      errorManager.handle(
        error,
        context: "BudgetRepository.fetchBudget(category:month:year:)"
      )
      return nil
    }
  }

  func createBudget(_ budget: Budget) async throws {
    do {
      guard let userId = budget.user?.id else {
        throw AppError.dataNotFound // Or another appropriate error
      }
      // Verifica se já existe orçamento para essa categoria/mês/ano
      if let existingBudget = try await fetchBudget(
        for: userId,
        category: budget.category,
        month: budget.month,
        year: budget.year
      ) {
        throw AppError.budgetAlreadyExists(
          category: budget.category.displayName
        )
      }

      modelContext.insert(budget)
      try modelContext.save()

      // Analytics - orçamento criado
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_created",
          parameters: [
            "category": budget.category.rawValue,
            "limit": budget.limit.doubleValue,
            "month": budget.month,
            "year": budget.year,
          ]
        )
      )

      errorManager.logInfo(
        "Orçamento criado: \(budget.category.displayName) - \(budget.limit)",
        context: "BudgetRepository.createBudget"
      )
    } catch {
      errorManager.handle(error, context: "BudgetRepository.createBudget")
      throw error
    }
  }

  func updateBudget(_ budget: Budget) async throws {
    do {
      try modelContext.save()

      // Analytics - orçamento atualizado
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_updated",
          parameters: [
            "category": budget.category.rawValue,
            "limit": budget.limit.doubleValue,
            "spent": budget.spent.doubleValue,
            "budget_id": budget.id.uuidString,
          ]
        )
      )

      errorManager.logInfo(
        "Orçamento atualizado: \(budget.category.displayName)",
        context: "BudgetRepository.updateBudget"
      )
    } catch {
      errorManager.handle(error, context: "BudgetRepository.updateBudget")
      throw AppError.unknown(underlying: error)
    }
  }

  func deleteBudget(_ budget: Budget) async throws {
    do {
      modelContext.delete(budget)
      try modelContext.save()

      // Analytics - orçamento deletado
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_deleted",
          parameters: [
            "category": budget.category.rawValue,
            "budget_id": budget.id.uuidString,
          ]
        )
      )

      errorManager.logInfo(
        "Orçamento deletado: \(budget.category.displayName)",
        context: "BudgetRepository.deleteBudget"
      )
    } catch {
      errorManager.handle(error, context: "BudgetRepository.deleteBudget")
      throw AppError.unknown(underlying: error)
    }
  }

  func updateSpentAmount(for budgetId: UUID, newAmount: Decimal) async throws {
    do {
      guard let budget = try await fetchBudget(by: budgetId) else {
        throw AppError.dataNotFound
      }

      budget.spent = newAmount
      try await updateBudget(budget)

      // Verifica se excedeu o limite
      if newAmount > budget.limit {
        firebaseService.logEvent(
          AnalyticsEvent(
            name: "budget_exceeded",
            parameters: [
              "category": budget.category.rawValue,
              "limit": budget.limit.doubleValue,
              "spent": newAmount.doubleValue,
              "excess": (newAmount - budget.limit).doubleValue,
            ]
          )
        )
      }

    } catch {
      errorManager.handle(error, context: "BudgetRepository.updateSpentAmount")
      throw error
    }
  }

  func getBudgetSummary(for userId: UUID, month: Int, year: Int) async throws
    -> BudgetSummary
  {
    do {
      let budgets = try await fetchBudgets(
        for: userId,
        month: month,
        year: year
      )

      let totalBudgeted = budgets.reduce(0) { $0 + $1.limit }
      let totalSpent = budgets.reduce(0) { $0 + $1.spent }
      let totalRemaining = totalBudgeted - totalSpent
      let overBudgetCount = budgets.filter { $0.spent > $0.limit }.count

      let utilizationPercentage: Double
      if totalBudgeted > 0 {
        utilizationPercentage = (totalSpent / totalBudgeted).doubleValue * 100
      } else {
        utilizationPercentage = 0
      }

      return BudgetSummary(
        totalBudgeted: totalBudgeted,
        totalSpent: totalSpent,
        totalRemaining: totalRemaining,
        budgetCount: budgets.count,
        overBudgetCount: overBudgetCount,
        utilizationPercentage: utilizationPercentage
      )
    } catch {
      errorManager.handle(error, context: "BudgetRepository.getBudgetSummary")
      throw error
    }
  }

  func checkBudgetLimits(
    for userId: UUID,
    category: TransactionCategory,
    amount: Decimal
  ) async throws -> BudgetAlert? {
    let currentDate = Date()
    let calendar = Calendar.current
    let month = calendar.component(.month, from: currentDate)
    let year = calendar.component(.year, from: currentDate)

    guard
      let budget = try await fetchBudget(
        for: userId,
        category: category,
        month: month,
        year: year
      )
    else {
      return nil  // Não há orçamento para esta categoria
    }

    let newSpentAmount = budget.spent + amount
    let utilizationPercentage = (newSpentAmount / budget.limit).doubleValue

    if utilizationPercentage >= 1.0 {
      return BudgetAlert(
        budget: budget,
        alertType: newSpentAmount > budget.limit ? .exceeded : .danger,
        message: newSpentAmount > budget.limit
          ? "Orçamento de \(budget.category.displayName) excedido!"
          : "Orçamento de \(budget.category.displayName) esgotado!"
      )
    } else if utilizationPercentage >= 0.8 {
      let remaining = budget.limit - newSpentAmount
      return BudgetAlert(
        budget: budget,
        alertType: .warning,
        message:
          "Atenção: Restam apenas \(remaining.formatted(.currency(code: "BRL"))) no orçamento de \(budget.category.displayName)"
      )
    }

    return nil
  }
}

