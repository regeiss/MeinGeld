//
//  AccountRepository.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 27/07/25.
//

import Foundation
import SwiftData

protocol AccountRepositoryProtocol: Sendable {
  func fetchAccounts(for userId: UUID) async throws -> [Account]
  func fetchAccount(by id: UUID) async throws -> Account?
  func createAccount(_ account: Account) async throws
  func updateAccount(_ account: Account) async throws
  func deleteAccount(_ account: Account) async throws
  func getTotalBalance(for userId: UUID) async throws -> Decimal
  func getAccountsByType(_ type: AccountType, for userId: UUID) async throws
    -> [Account]
}

@MainActor
final class AccountRepository: AccountRepositoryProtocol {
  private let modelContext: ModelContext
  private let errorManager: ErrorManagerProtocol
  private let firebaseService: FirebaseServiceProtocol

  init(
    modelContext: ModelContext,
    errorManager: ErrorManagerProtocol? = nil,
    firebaseService: FirebaseServiceProtocol? = nil
  ) {
    self.modelContext = modelContext
    self.errorManager = errorManager ?? ErrorManager.shared
    self.firebaseService = firebaseService ?? FirebaseService.shared
  }

  func fetchAccounts(for userId: UUID) async throws -> [Account] {
    do {
      let descriptor = FetchDescriptor<Account>(
        predicate: #Predicate<Account> { $0.user.id == userId && $0.isActive },
        sortBy: [SortDescriptor(\.name)]
      )
      let accounts = try modelContext.fetch(descriptor)

      errorManager.logInfo(
        "Contas carregadas: \(accounts.count) para usuário \(userId)",
        context: "AccountRepository.fetchAccounts"
      )

      return accounts
    } catch {
      errorManager.handle(error, context: "AccountRepository.fetchAccounts")
      throw AppError.dataNotFound
    }
  }

  func fetchAccount(by id: UUID) async throws -> Account? {
    do {
      let descriptor = FetchDescriptor<Account>(
        predicate: #Predicate<Account> { $0.id == id }
      )
      let accounts = try modelContext.fetch(descriptor)

      return accounts.first
    } catch {
      errorManager.handle(error, context: "AccountRepository.fetchAccount")
      throw AppError.accountNotFound
    }
  }

  func createAccount(_ account: Account) async throws {
    do {
      modelContext.insert(account)
      try modelContext.save()

      // Analytics - conta criada
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_created",
          parameters: [
            "account_type": account.accountType.rawValue,
            "initial_balance": account.balance.doubleValue,
          ]
        )
      )

      errorManager.logInfo(
        "Conta criada: \(account.name)",
        context: "AccountRepository.createAccount"
      )
    } catch {
      errorManager.handle(error, context: "AccountRepository.createAccount")
      throw AppError.unknown(underlying: error)
    }
  }

  func updateAccount(_ account: Account) async throws {
    do {
      try modelContext.save()

      // Analytics - conta atualizada
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_updated",
          parameters: [
            "account_type": account.accountType.rawValue,
            "account_id": account.id.uuidString,
          ]
        )
      )

      errorManager.logInfo(
        "Conta atualizada: \(account.name)",
        context: "AccountRepository.updateAccount"
      )
    } catch {
      errorManager.handle(error, context: "AccountRepository.updateAccount")
      throw AppError.unknown(underlying: error)
    }
  }

  func deleteAccount(_ account: Account) async throws {
    do {
      // Verifica se há transações associadas
      if !account.transactions.isEmpty {
        throw AppError.accountHasTransactions
      }

      modelContext.delete(account)
      try modelContext.save()

      // Analytics - conta deletada
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_deleted",
          parameters: [
            "account_type": account.accountType.rawValue,
            "account_id": account.id.uuidString,
          ]
        )
      )

      errorManager.logInfo(
        "Conta deletada: \(account.name)",
        context: "AccountRepository.deleteAccount"
      )
    } catch {
      errorManager.handle(error, context: "AccountRepository.deleteAccount")
      throw error
    }
  }

  func getTotalBalance(for userId: UUID) async throws -> Decimal {
    do {
      let accounts = try await fetchAccounts(for: userId)
      let total = accounts.reduce(0) { $0 + $1.balance }

      errorManager.logInfo(
        "Saldo total calculado: \(total)",
        context: "AccountRepository.getTotalBalance"
      )

      return total
    } catch {
      errorManager.handle(error, context: "AccountRepository.getTotalBalance")
      throw error
    }
  }

  func getAccountsByType(_ type: AccountType, for userId: UUID) async throws
    -> [Account]
  {
    do {
      let descriptor = FetchDescriptor<Account>(
        predicate: #Predicate<Account> {
          $0.user.id == userId && $0.accountType == type && $0.isActive
        },
        sortBy: [SortDescriptor(\.name)]
      )
      let accounts = try modelContext.fetch(descriptor)

      return accounts
    } catch {
      errorManager.handle(error, context: "AccountRepository.getAccountsByType")
      throw AppError.dataNotFound
    }
  }
}

