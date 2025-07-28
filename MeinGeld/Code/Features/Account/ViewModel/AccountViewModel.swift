//
//  AccountViewModel.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//
import Foundation
import SwiftData

@Observable
@MainActor
final class AccountViewModel {
  private let repository: AccountRepositoryProtocol
  private let authManager: AuthenticationManager
  private let errorManager: ErrorManagerProtocol

  var accounts: [Account] = []
  var isLoading = false
  var errorMessage: String?

  // Computed properties
  var totalBalance: Decimal {
    accounts.reduce(0) { $0 + $1.balance }
  }

  var checkingAccounts: [Account] {
    accounts.filter { $0.accountType == .checking }
  }

  var savingsAccounts: [Account] {
    accounts.filter { $0.accountType == .savings }
  }

  var creditAccounts: [Account] {
    accounts.filter { $0.accountType == .credit }
  }

  var investmentAccounts: [Account] {
    accounts.filter { $0.accountType == .investment }
  }

  init(
    repository: AccountRepositoryProtocol,
    authManager: AuthenticationManager? = nil,
    errorManager: ErrorManagerProtocol? = nil
  ) {
    self.repository = repository
    self.authManager = authManager ?? AuthenticationManager.shared
    self.errorManager = errorManager ?? ErrorManager.shared
  }

  // MARK: - Public Methods

  func loadAccounts() async {
    guard let currentUser = authManager.currentUser else {
      errorManager.logWarning(
        "Usuário não autenticado",
        context: "AccountViewModel.loadAccounts"
      )
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      accounts = try await repository.fetchAccounts(for: currentUser.id)
    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "AccountViewModel.loadAccounts")
    }

    isLoading = false
  }

  func createAccount(
    name: String,
    initialBalance: Decimal,
    accountType: AccountType
  ) async -> Bool {
    guard let currentUser = authManager.currentUser else {
      errorMessage = "Usuário não encontrado"
      return false
    }

    guard !name.isEmpty else {
      errorMessage = "Nome da conta é obrigatório"
      return false
    }

    isLoading = true
    errorMessage = nil

    do {
      let account = Account(
        name: name,
        balance: initialBalance,
        accountType: accountType,
        user: currentUser
      )

      try await repository.createAccount(account)
      await loadAccounts()  // Recarrega a lista

      isLoading = false
      return true
    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "AccountViewModel.createAccount")
      isLoading = false
      return false
    }
  }

  func updateAccount(_ account: Account) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      try await repository.updateAccount(account)
      await loadAccounts()  // Recarrega a lista

      isLoading = false
      return true
    } catch {
      errorMessage = error.localizedDescription
      errorManager.handle(error, context: "AccountViewModel.updateAccount")
      isLoading = false
      return false
    }
  }

  func deleteAccount(_ account: Account) async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      try await repository.deleteAccount(account)
      await loadAccounts()  // Recarrega a lista

      isLoading = false
      return true
    } catch {
      if let appError = error as? AppError,
        appError == .accountHasTransactions
      {
        errorMessage = "Não é possível deletar conta com transações"
      } else {
        errorMessage = error.localizedDescription
      }
      errorManager.handle(error, context: "AccountViewModel.deleteAccount")
      isLoading = false
      return false
    }
  }

  func getAccount(by id: UUID) async -> Account? {
    do {
      return try await repository.fetchAccount(by: id)
    } catch {
      errorManager.handle(error, context: "AccountViewModel.getAccount")
      return nil
    }
  }

  func updateBalance(for account: Account, newBalance: Decimal) async -> Bool {
    account.balance = newBalance
    return await updateAccount(account)
  }

  // MARK: - Analytics Methods

  func trackAccountViewed() {
    FirebaseService.shared.logEvent(.accountsViewed)
  }

  func trackAccountInteraction(action: String, accountType: AccountType) {
    FirebaseService.shared.logEvent(
      AnalyticsEvent(
        name: "account_interaction",
        parameters: [
          "action": action,
          "account_type": accountType.rawValue,
        ]
      )
    )
  }
}

