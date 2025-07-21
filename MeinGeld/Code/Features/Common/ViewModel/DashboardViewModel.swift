//
//  DashboardViewModel.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {

  // MARK: - Published Properties
  var totalBalance: Decimal = 0
  var monthlyIncome: Decimal = 0
  var monthlyExpenses: Decimal = 0
  var recentTransactions: [Transaction] = []
  var accounts: [Account] = []
  var incomeVsExpensesData:
    [(month: String, income: Decimal, expenses: Decimal)] = []
  var isLoading = false
  var errorMessage: String?

  // MARK: - Private Properties
  private let dataService: DataServiceProtocol
  private let authManager: any AuthenticationManagerProtocol
  private let firebaseService: FirebaseServiceProtocol

  // MARK: - Initialization
  init(
    dataService: DataServiceProtocol,
    authManager: any AuthenticationManagerProtocol,
    firebaseService: FirebaseServiceProtocol = FirebaseService.shared
  ) {
    self.dataService = dataService
    self.authManager = authManager
    self.firebaseService = firebaseService
  }

  // MARK: - Public Methods
  func loadDashboardData() async {
    guard let user = authManager.currentUser else {
      errorMessage = "Usuário não autenticado"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      // Load accounts and total balance
      accounts = try await dataService.fetchAccounts(for: user)
      totalBalance = try await dataService.fetchTotalBalance(for: user)

      // Load recent transactions
      recentTransactions = try await dataService.fetchTransactions(
        for: user,
        limit: 5,
        offset: 0
      )

      // Load income vs expenses data for last 6 months
      incomeVsExpensesData = try await dataService.fetchIncomeVsExpenses(
        for: user,
        months: 6
      )

      // Calculate current month income and expenses
      let currentDate = Date()
      let startOfMonth =
        Calendar.current.dateInterval(of: .month, for: currentDate)?.start
        ?? currentDate
      let endOfMonth =
        Calendar.current.dateInterval(of: .month, for: currentDate)?.end
        ?? currentDate

      let monthlyTransactions =
        try await dataService.fetchTransactionsByDateRange(
          from: startOfMonth,
          to: endOfMonth,
          for: user
        )

      monthlyIncome =
        monthlyTransactions
        .filter { $0.type == .income }
        .reduce(0) { $0 + $1.amount }

      monthlyExpenses =
        monthlyTransactions
        .filter { $0.type == .expense }
        .reduce(0) { $0 + abs($1.amount) }

      firebaseService.logEvent(.dashboardViewed)

    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func refreshData() async {
    await loadDashboardData()
  }

  // MARK: - Computed Properties
  var monthlySavings: Decimal {
    monthlyIncome - monthlyExpenses
  }

  var savingsRate: Double {
    guard monthlyIncome > 0 else { return 0.0 }
    return (monthlySavings.doubleValue / monthlyIncome.doubleValue) * 100
  }

  var topAccounts: [Account] {
    Array(accounts.prefix(3))
  }
}
