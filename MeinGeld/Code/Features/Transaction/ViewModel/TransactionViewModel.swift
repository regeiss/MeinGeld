//
//  TransactionViewModel.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class TransactionViewModel {

  // MARK: - Published Properties
  var transactions: [Transaction] = []
  var isLoading = false
  var isLoadingMore = false
  var errorMessage: String?
  var hasMoreData = true

  // MARK: - Private Properties
  private let dataService: DataServiceProtocol
  private let authManager: any AuthenticationManagerProtocol
  private let firebaseService: FirebaseServiceProtocol

  private var currentPage = 0
  private let pageSize = 50

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
  func loadTransactions() async {
    guard let user = authManager.currentUser else {
      errorMessage = "Usuário não autenticado"
      return
    }

    isLoading = true
    errorMessage = nil
    currentPage = 0

    do {
      let fetchedTransactions = try await dataService.fetchTransactions(
        for: user,
        limit: pageSize,
        offset: 0
      )

      transactions = fetchedTransactions
      hasMoreData = fetchedTransactions.count == pageSize

      firebaseService.logEvent(.transactionsViewed)

    } catch {
      errorMessage = error.localizedDescription
      transactions = []
    }

    isLoading = false
  }

  func loadMoreTransactions() async {
    guard let user = authManager.currentUser,
      hasMoreData,
      !isLoadingMore
    else { return }

    isLoadingMore = true
    currentPage += 1

    do {
      let fetchedTransactions = try await dataService.fetchTransactions(
        for: user,
        limit: pageSize,
        offset: currentPage * pageSize
      )

      transactions.append(contentsOf: fetchedTransactions)
      hasMoreData = fetchedTransactions.count == pageSize

    } catch {
      errorMessage = error.localizedDescription
      currentPage -= 1  // Revert page increment
    }

    isLoadingMore = false
  }

  func addTransaction(
    amount: Decimal,
    description: String,
    category: TransactionCategory,
    type: TransactionType,
    account: Account?
  ) async {
    guard !description.isEmpty, amount > 0 else {
      errorMessage = "Dados inválidos"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      let finalAmount = type == .expense ? -amount : amount
      let transaction = Transaction(
        amount: finalAmount,
        description: description,
        date: Date(),
        category: category,
        type: type,
        account: account
      )

      try await dataService.createTransaction(transaction)

      // Refresh transactions to show the new one
      await loadTransactions()

    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func deleteTransaction(_ transaction: Transaction) async {
    isLoading = true
    errorMessage = nil

    do {
      try await dataService.deleteTransaction(transaction)

      // Remove from local array
      transactions.removeAll { $0.id == transaction.id }

    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func filterTransactions(by category: TransactionCategory) async {
    guard let user = authManager.currentUser else {
      errorMessage = "Usuário não autenticado"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      transactions = try await dataService.fetchTransactionsByCategory(
        category,
        for: user
      )
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func filterTransactions(from startDate: Date, to endDate: Date) async {
    guard let user = authManager.currentUser else {
      errorMessage = "Usuário não autenticado"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      transactions = try await dataService.fetchTransactionsByDateRange(
        from: startDate,
        to: endDate,
        for: user
      )
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func clearFilters() async {
    await loadTransactions()
  }
}
