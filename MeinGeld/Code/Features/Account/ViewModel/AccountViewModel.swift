//
//  AccountViewModel.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//
import Foundation
import SwiftData

@MainActor
@Observable
final class AccountViewModel {

  // MARK: - Published Properties
  var accounts: [Account] = []
  var totalBalance: Decimal = 0
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
  func loadAccounts() async {
    guard let user = authManager.currentUser else {
      errorMessage = "Usuário não autenticado"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      accounts = try await dataService.fetchAccounts(for: user)
      totalBalance = try await dataService.fetchTotalBalance(for: user)

      firebaseService.logEvent(.accountsViewed)

    } catch {
      errorMessage = error.localizedDescription
      accounts = []
      totalBalance = 0
    }

    isLoading = false
  }

  func createAccount(
    name: String,
    accountType: AccountType,
    initialBalance: Decimal = 0
  ) async {
    guard let user = authManager.currentUser,
      !name.isEmpty
    else {
      errorMessage = "Dados inválidos"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      let account = Account(
        name: name,
        balance: initialBalance,
        accountType: accountType,
        user: user
      )

      try await dataService.createAccount(account)

      // Refresh accounts
      await loadAccounts()

    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func updateAccount(_ account: Account) async {
    isLoading = true
    errorMessage = nil

    do {
      try await dataService.updateAccount(account)

      // Update local array
      if let index = accounts.firstIndex(where: { $0.id == account.id }) {
        accounts[index] = account
      }

      // Recalculate total balance
      if let user = authManager.currentUser {
        totalBalance = try await dataService.fetchTotalBalance(for: user)
      }

    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func deleteAccount(_ account: Account) async {
    isLoading = true
    errorMessage = nil

    do {
      try await dataService.deleteAccount(account)

      // Remove from local array
      accounts.removeAll { $0.id == account.id }

      // Recalculate total balance
      if let user = authManager.currentUser {
        totalBalance = try await dataService.fetchTotalBalance(for: user)
      }

    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }
}

