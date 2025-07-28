//
//  TransactionRepository.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 23/07/25.
//

import Foundation
import SwiftData

// MARK: - Repository Protocol
@MainActor
protocol TransactionRepositoryProtocol {
  func fetchTransactions(for userId: UUID) async throws -> [Transaction]
  func fetchRecentTransactions(for userId: UUID, limit: Int) async throws
    -> [Transaction]
  func createTransaction(_ transaction: Transaction) async throws
  func deleteTransaction(_ transaction: Transaction) async throws
}

// MARK: - Repository Implementation
final class TransactionRepository: TransactionRepositoryProtocol {
  private let modelContext: ModelContext
  private let errorManager: ErrorManagerProtocol

  // Cache for better performance
  private var cachedTransactions: [UUID: [Transaction]] = [:]
  private var lastFetchTime: [UUID: Date] = [:]
  private let cacheTimeout: TimeInterval = 300  // 5 minutes

  init(modelContext: ModelContext, errorManager: ErrorManagerProtocol) {
    self.modelContext = modelContext
    self.errorManager = errorManager
  }

  func fetchTransactions(for userId: UUID) async throws -> [Transaction] {
    // Check cache first
    if let cached = cachedTransactions[userId],
      let lastFetch = lastFetchTime[userId],
      Date().timeIntervalSince(lastFetch) < cacheTimeout
    {
      return cached
    }

    let descriptor = FetchDescriptor<Transaction>(
      predicate: #Predicate<Transaction> { $0.account?.user.id == userId },
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )

    do {
      let transactions = try modelContext.fetch(descriptor)

      // Update cache
      cachedTransactions[userId] = transactions
      lastFetchTime[userId] = Date()

      return transactions
    } catch {
      errorManager.handle(
        error,
        context: "TransactionRepository.fetchTransactions"
      )
      throw error
    }
  }

  func fetchRecentTransactions(for userId: UUID, limit: Int) async throws
    -> [Transaction]
  {
    let allTransactions = try await fetchTransactions(for: userId)
    return Array(allTransactions.prefix(limit))
  }

  func createTransaction(_ transaction: Transaction) async throws {
    modelContext.insert(transaction)
    try modelContext.save()

    // Invalidate cache
    if let account = transaction.account {
      let userId = account.user.id
      cachedTransactions.removeValue(forKey: userId)
      lastFetchTime.removeValue(forKey: userId)
    }
  }

  func deleteTransaction(_ transaction: Transaction) async throws {
    let userId = transaction.account?.user.id
    modelContext.delete(transaction)
    try modelContext.save()

    // Invalidate cache
    if let userId = userId {
        cachedTransactions.removeValue(forKey: userId)
        lastFetchTime.removeValue(forKey: userId)
    }
  }
}
