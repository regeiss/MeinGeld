//
//  DataServiceProtocol.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftData

// MARK: - Data Service Protocol
protocol DataServiceProtocol: Sendable {
  // MARK: - Container Management
  func getModelContainer() -> ModelContainer
  func getMainContext() -> ModelContext
  func saveContext() throws

  // MARK: - User Operations
  func createUser(_ user: User) async throws
  func fetchUser(by id: UUID) async throws -> User?
  func fetchUser(by email: String) async throws -> User?
  func updateUser(_ user: User) async throws
  func deleteUser(_ user: User) async throws

  // MARK: - Account Operations
  func createAccount(_ account: Account) async throws
  func fetchAccounts(for user: User) async throws -> [Account]
  func updateAccount(_ account: Account) async throws
  func deleteAccount(_ account: Account) async throws

  // MARK: - Transaction Operations
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

  // MARK: - Budget Operations
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

  // MARK: - Analytics & Reports
  func fetchTotalBalance(for user: User) async throws -> Decimal
  func fetchExpensesByCategory(for user: User, month: Int, year: Int)
    async throws -> [String: Decimal]
  func fetchIncomeVsExpenses(for user: User, months: Int) async throws -> [(
    month: String, income: Decimal, expenses: Decimal
  )]

  // MARK: - Sample Data
  func generateSampleData() async throws
  func clearAllData() async throws
}

// MARK: - Data Service Errors
enum DataServiceError: LocalizedError, Sendable {
  case contextNotAvailable
  case entityNotFound
  case invalidData
  case saveOperationFailed(Error)
  case fetchOperationFailed(Error)
  case containerCreationFailed(Error)
  case sampleDataGenerationFailed(Error)

  var errorDescription: String? {
    switch self {
    case .contextNotAvailable:
      return "Contexto de dados não disponível"
    case .entityNotFound:
      return "Entidade não encontrada"
    case .invalidData:
      return "Dados inválidos"
    case .saveOperationFailed(let error):
      return "Falha ao salvar dados: \(error.localizedDescription)"
    case .fetchOperationFailed(let error):
      return "Falha ao buscar dados: \(error.localizedDescription)"
    case .containerCreationFailed(let error):
      return "Falha ao criar container: \(error.localizedDescription)"
    case .sampleDataGenerationFailed(let error):
      return "Falha ao gerar dados de exemplo: \(error.localizedDescription)"
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
