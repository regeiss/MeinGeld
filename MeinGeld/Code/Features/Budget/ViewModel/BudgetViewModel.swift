//
//  BudgetViewModel.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class BudgetViewModel {
  private let repository: BudgetRepositoryProtocol
  private let authManager: AuthenticationManager
  private let errorManager: ErrorManagerProtocol

  var budgets: [Budget] = []
  var currentMonthBudgets: [Budget] = []
  var budgetSummary: BudgetSummary?
  var isLoading = false
  var errorMessage: String?

  var selectedMonth: Int
  var selectedYear: Int

  // Computed properties
  var totalBudgeted: Decimal {
    currentMonthBudgets.reduce(0) { $0 + $1.limit }
  }

  var totalSpent: Decimal {
    currentMonthBudgets.reduce(0) { $0 + $1.spent }
  }

  var totalRemaining: Decimal {
    totalBudgeted - totalSpent
  }

  var overBudgetCount: Int {
    currentMonthBudgets.filter { $0.spent > $0.limit }.count
  }

  var budgetsByCategory: [TransactionCategory: Budget] {
    Dictionary(uniqueKeysWithValues: currentMonthBudgets.compactMap { budget in
      guard let category = budget.category as? TransactionCategory ?? TransactionCategory(rawValue: (budget.category as? String) ?? "") else {
        return nil
      }
      return (category, budget)
    })
  }

  init(
    repository: BudgetRepositoryProtocol,
    authManager: AuthenticationManager,
    errorManager: ErrorManagerProtocol
  ) {
    self.repository = repository
    self.authManager = authManager
    self.errorManager = errorManager

    let currentDate = Date()
    let calendar = Calendar.current
    self.selectedMonth = calendar.component(.month, from: currentDate)
    self.selectedYear = calendar.component(.year, from: currentDate)
  }

  // MARK: - Public Methods

  func loadBudgets() async {
    guard let currentUser = authManager.currentUser else {
      errorManager.logWarning(
        "Usuário não autenticado",
        context: "BudgetViewModel.loadBudgets"
      )
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      // Carrega todos os orçamentos
      budgets = try await repository.fetchBudgets(for: currentUser.id)

      // Carrega orçamentos do mês/ano selecionado
      currentMonthBudgets = try await repository.fetchBudgets(
        for: currentUser.id,
        month: selectedMonth,
        year: selectedYear
      )

      // Carrega resumo
      budgetSummary = try await repository.getBudgetSummary(
        for: currentUser.id,
        month: selectedMonth,
        year: selectedYear
      )

    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "BudgetViewModel.loadBudgets")
    }

    isLoading = false
  }

  func createBudget(
    category: TransactionCategory,
    limit: Decimal,
    month: Int? = nil,
    year: Int? = nil
  ) async -> Bool {
    guard let currentUser = authManager.currentUser else {
      errorMessage = "Usuário não encontrado"
      return false
    }

    guard limit > 0 else {
      errorMessage = "Limite deve ser maior que zero"
      return false
    }

    isLoading = true
    errorMessage = nil

    do {
      let budget = Budget(
        category: category,
        limit: limit,
        month: month ?? selectedMonth,
        year: year ?? selectedYear,
        user: currentUser
      )

      try await repository.createBudget(budget)
      await loadBudgets()  // Recarrega a lista

      isLoading = false
      return true
    } catch {
      if let appError = error as? AppError,
        case .budgetAlreadyExists(let categoryName) = appError
      {
        errorMessage = "Já existe orçamento para \(categoryName) neste período"
      } else {
        errorMessage = error.localizedDescription
      }
      errorManager.handle(error, context: "BudgetViewModel.createBudget")
      isLoading = false
      return false
    }
  }

  func updateBudget(_ budget: Budget) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      try await repository.updateBudget(budget)
      await loadBudgets()  // Recarrega a lista

      isLoading = false
      return true
    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "BudgetViewModel.updateBudget")
      isLoading = false
      return false
    }
  }

  func deleteBudget(_ budget: Budget) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      try await repository.deleteBudget(budget)
      await loadBudgets()  // Recarrega a lista

      isLoading = false
      return true
    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "BudgetViewModel.deleteBudget")
      isLoading = false
      return false
    }
  }

  func changeMonth(to month: Int, year: Int) async {
    selectedMonth = month
    selectedYear = year
    await loadBudgets()
  }

  func updateSpentAmount(for budget: Budget, newAmount: Decimal) async -> Bool {
    do {
      try await repository.updateSpentAmount(
        for: budget.id,
        newAmount: newAmount
      )
      await loadBudgets()
      return true
    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "BudgetViewModel.updateSpentAmount")
      return false
    }
  }

  func checkBudgetAlert(
    for category: TransactionCategory,
    transactionAmount: Decimal
  ) async -> BudgetAlert? {
    guard let currentUser = authManager.currentUser else { return nil }

    do {
      return try await repository.checkBudgetLimits(
        for: currentUser.id,
        category: category,
        amount: transactionAmount
      )
    } catch {
      errorManager.handle(error, context: "BudgetViewModel.checkBudgetAlert")
      return nil
    }
  }

  func getBudgetProgress(for category: TransactionCategory) -> Double {
    guard let budget = budgetsByCategory[category] else { return 0 }
    guard budget.limit > 0 else { return 0 }

    return min((budget.spent / budget.limit).doubleValue, 1.0)
  }

  func getRemainingAmount(for category: TransactionCategory) -> Decimal {
    guard let budget = budgetsByCategory[category] else { return 0 }
    return max(budget.limit - budget.spent, 0)
  }

  // MARK: - Analytics Methods

  func trackBudgetViewed() {
    FirebaseService.shared.logEvent(.budgetViewed)
  }

  func trackBudgetInteraction(action: String, category: TransactionCategory) {
    FirebaseService.shared.logEvent(
      AnalyticsEvent(
        name: "budget_interaction",
        parameters: [
          "action": action,
          "category": category.rawValue,
        ]
      )
    )
  }

  func trackMonthChanged(month: Int, year: Int) {
    FirebaseService.shared.logEvent(
      AnalyticsEvent(
        name: "budget_month_changed",
        parameters: [
          "month": month,
          "year": year,
        ]
      )
    )
  }
}

