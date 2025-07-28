//
//  DataServiceProtocol.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftData

// MARK: - Data Service Protocol
protocol DataServiceProtocol {
  func getModelContainer() -> ModelContainer
  func getMainContext() -> ModelContext
  func saveContext() throws

  // User Operations
  func createUser(_ user: User) async throws
  func fetchUser(by id: UUID) async throws -> User?
  func fetchUser(by email: String) async throws -> User?
  func updateUser(_ user: User) async throws
  func deleteUser(_ user: User) async throws

  // Account Operations
  func createAccount(_ account: Account) async throws
  func fetchAccounts(for user: User) async throws -> [Account]
  func updateAccount(_ account: Account) async throws
  func deleteAccount(_ account: Account) async throws

  // Transaction Operations
  func createTransaction(_ transaction: Transaction) async throws
  func fetchTransactions(for user: User, limit: Int?, offset: Int?) async throws
    -> [Transaction]
  func fetchTransactions(for account: Account, limit: Int?, offset: Int?)
    async throws -> [Transaction]
  func fetchTransactionsByCategory(
    _ category: TransactionCategory,
    for user: User
  ) async throws -> [Transaction]
  func fetchTransactionsByDateRange(
    from startDate: Date,
    to endDate: Date,
    for user: User
  ) async throws -> [Transaction]
  func updateTransaction(_ transaction: Transaction) async throws
  func deleteTransaction(_ transaction: Transaction) async throws

  // Budget Operations
  func createBudget(_ budget: Budget) async throws
  func fetchBudgets(for user: User) async throws -> [Budget]
  func fetchBudget(
    for category: TransactionCategory,
    month: Int,
    year: Int,
    user: User
  ) async throws -> Budget?
  func updateBudget(_ budget: Budget) async throws
  func deleteBudget(_ budget: Budget) async throws

  // Analytics & Reports
  func fetchTotalBalance(for user: User) async throws -> Decimal
  func fetchExpensesByCategory(for user: User, month: Int, year: Int)
    async throws -> [String: Decimal]
  func fetchIncomeVsExpenses(for user: User, months: Int) async throws -> [(
    month: String, income: Decimal, expenses: Decimal
  )]

  // Sample Data
  func generateSampleData() async throws
  func clearAllData() async throws
}

// MARK: - Data Service Errors
enum DataServiceError: LocalizedError, Sendable {
  case containerCreationFailed(Error)
  case saveOperationFailed(Error)
  case fetchOperationFailed(Error)
  case entityNotFound
  case sampleDataGenerationFailed(Error)
  case invalidOperation

  var errorDescription: String? {
    switch self {
    case .containerCreationFailed(let error):
      return "Falha ao criar container de dados: \(error.localizedDescription)"
    case .saveOperationFailed(let error):
      return "Falha ao salvar dados: \(error.localizedDescription)"
    case .fetchOperationFailed(let error):
      return "Falha ao buscar dados: \(error.localizedDescription)"
    case .entityNotFound:
      return "Entidade não encontrada"
    case .sampleDataGenerationFailed(let error):
      return "Falha ao gerar dados de exemplo: \(error.localizedDescription)"
    case .invalidOperation:
      return "Operação inválida"
    }
  }
}

// MARK: - Extensions
extension Calendar {
  fileprivate func dateFormat(_ format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.calendar = self
    return formatter
  }
}
