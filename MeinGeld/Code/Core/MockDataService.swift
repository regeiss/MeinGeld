//
//  MockDataService.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//
//

import Foundation
import SwiftData

// MARK: - Mock Data Service
@MainActor
final class MockDataService: DataServiceProtocol {

  // MARK: - Mock Data Storage
  private var users: [User] = []
  private var accounts: [Account] = []
  private var transactions: [Transaction] = []
  private var budgets: [Budget] = []

  // MARK: - Configuration
  var shouldThrowErrors = false
  var networkDelay: TimeInterval = 0.1

  // MARK: - Mock Container
  private var mockContainer: ModelContainer {
    do {
      let schema = Schema([
        Transaction.self, Account.self, Budget.self, User.self,
      ])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true
      )
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create mock container: \(error)")
    }
  }

  init() {
    setupMockData()
  }

  // MARK: - Container Management
  func getModelContainer() -> ModelContainer {
    return mockContainer
  }

  func getMainContext() -> ModelContext {
    return mockContainer.mainContext
  }

  func saveContext() throws {
    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }
    // Mock save - no-op
  }

  // MARK: - User Operations
  func createUser(_ user: User) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    users.append(user)
  }

  func fetchUser(by id: UUID) async throws -> User? {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    return users.first { $0.id == id }
  }

  func fetchUser(by email: String) async throws -> User? {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    return users.first { $0.email == email }
  }

  func updateUser(_ user: User) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    if let index = users.firstIndex(where: { $0.id == user.id }) {
      users[index] = user
    }
  }

  func deleteUser(_ user: User) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    // ✅ CORRIGIDO: Acesso seguro aos optionals
    users.removeAll { $0.id == user.id }
    accounts.removeAll { $0.user.id == user.id }
    transactions.removeAll { $0.account?.user.id == user.id }
    budgets.removeAll { $0.user?.id == user.id }
  }

  // MARK: - Account Operations
  func createAccount(_ account: Account) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    accounts.append(account)
  }

  func fetchAccounts(for user: User) async throws -> [Account] {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    // ✅ CORRIGIDO: Acesso seguro aos optionals
    return accounts.filter { $0.user.id == user.id && $0.isActive }
  }

  func updateAccount(_ account: Account) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    if let index = accounts.firstIndex(where: { $0.id == account.id }) {
      accounts[index] = account
    }
  }

  func deleteAccount(_ account: Account) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    if let index = accounts.firstIndex(where: { $0.id == account.id }) {
      accounts[index].isActive = false
    }
  }

  // MARK: - Transaction Operations
  func createTransaction(_ transaction: Transaction) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    transactions.append(transaction)

    // Update account balance
    if let accountId = transaction.account?.id,
      let accountIndex = accounts.firstIndex(where: { $0.id == accountId })
    {
      accounts[accountIndex].balance += transaction.amount
    }
  }

  func fetchTransactions(for user: User, limit: Int? = nil, offset: Int? = nil)
    async throws -> [Transaction]
  {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    // ✅ CORRIGIDO: Acesso seguro aos optionals
    var userTransactions =
      transactions
      .filter { $0.account?.user.id == user.id }
      .sorted { $0.date > $1.date }

    if let offset = offset {
      userTransactions = Array(userTransactions.dropFirst(offset))
    }

    if let limit = limit {
      userTransactions = Array(userTransactions.prefix(limit))
    }

    return userTransactions
  }

  func fetchTransactions(
    for account: Account,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [Transaction] {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    var accountTransactions =
      transactions
      .filter { $0.account?.id == account.id }
      .sorted { $0.date > $1.date }

    if let offset = offset {
      accountTransactions = Array(accountTransactions.dropFirst(offset))
    }

    if let limit = limit {
      accountTransactions = Array(accountTransactions.prefix(limit))
    }

    return accountTransactions
  }

  func fetchTransactionsByCategory(
    _ category: TransactionCategory,
    for user: User
  ) async throws -> [Transaction] {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    // ✅ CORRIGIDO: Acesso seguro aos optionals
    return
      transactions
      .filter { $0.category == category && $0.account?.user.id == user.id }
      .sorted { $0.date > $1.date }
  }

  func fetchTransactionsByDateRange(
    from startDate: Date,
    to endDate: Date,
    for user: User
  ) async throws -> [Transaction] {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    // ✅ CORRIGIDO: Acesso seguro aos optionals
    return
      transactions
      .filter {
        $0.date >= startDate && $0.date <= endDate
          && $0.account?.user.id == user.id
      }
      .sorted { $0.date > $1.date }
  }

  func updateTransaction(_ transaction: Transaction) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
      transactions[index] = transaction
    }
  }

  func deleteTransaction(_ transaction: Transaction) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    // Revert account balance
    if let accountId = transaction.account?.id,
      let accountIndex = accounts.firstIndex(where: { $0.id == accountId })
    {
      accounts[accountIndex].balance -= transaction.amount
    }

    transactions.removeAll { $0.id == transaction.id }
  }

  // MARK: - Budget Operations
  func createBudget(_ budget: Budget) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    budgets.append(budget)
  }

  func fetchBudgets(for user: User) async throws -> [Budget] {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    return budgets.filter { $0.user?.id == user.id }
  }

  func fetchBudget(
    for category: TransactionCategory,
    month: Int,
    year: Int,
    user: User
  ) async throws -> Budget? {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    return budgets.first {
      $0.category == category && $0.month == month && $0.year == year
        && $0.user?.id == user.id
    }
  }

  func updateBudget(_ budget: Budget) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
      budgets[index] = budget
    }
  }

  func deleteBudget(_ budget: Budget) async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    budgets.removeAll { $0.id == budget.id }
  }

  // MARK: - Analytics & Reports
  func fetchTotalBalance(for user: User) async throws -> Decimal {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    let userAccounts = try await fetchAccounts(for: user)
    return userAccounts.reduce(0) { $0 + $1.balance }
  }

  func fetchExpensesByCategory(for user: User, month: Int, year: Int)
    async throws -> [String: Decimal]
  {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    let calendar = Calendar.current
    let startDate =
      calendar.date(from: DateComponents(year: year, month: month, day: 1))
      ?? Date()
    let endDate =
      calendar.date(byAdding: .month, value: 1, to: startDate) ?? Date()

    let userTransactions = try await fetchTransactionsByDateRange(
      from: startDate,
      to: endDate,
      for: user
    )
    let expenses = userTransactions.filter { $0.type == .expense }

    var result: [String: Decimal] = [:]
    for expense in expenses {
      let categoryName = expense.category.displayName
      result[categoryName, default: 0] += abs(expense.amount)
    }

    return result
  }

  func fetchIncomeVsExpenses(for user: User, months: Int) async throws -> [(
    month: String, income: Decimal, expenses: Decimal
  )] {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.fetchOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    var result: [(month: String, income: Decimal, expenses: Decimal)] = []
    let calendar = Calendar.current
    let currentDate = Date()

    for i in 0..<months {
      guard
        let monthDate = calendar.date(
          byAdding: .month,
          value: -i,
          to: currentDate
        )
      else {
        continue
      }

      let monthComponent = calendar.component(.month, from: monthDate)
      let yearComponent = calendar.component(.year, from: monthDate)

      let monthName =
        calendar.monthSymbols[monthComponent - 1] + " \(yearComponent)"

      // Mock data - you can customize this
      let income = Decimal(Double.random(in: 3000...8000))
      let expenses = Decimal(Double.random(in: 1500...5000))

      result.append((month: monthName, income: income, expenses: expenses))
    }

    return result.reversed()
  }

  // MARK: - Sample Data
  func generateSampleData() async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.sampleDataGenerationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    guard users.isEmpty else { return }

    let sampleUser = User(
      email: "demo@exemplo.com",
      name: "Usuário Demo",
      preferredCurrency: "BRL"
    )

    try await createUser(sampleUser)

    // Create sample accounts
    let sampleAccounts = [
      Account(
        name: "Conta Corrente",
        balance: 2500.00,
        accountType: .checking,
        user: sampleUser
      ),
      Account(
        name: "Poupança",
        balance: 15000.00,
        accountType: .savings,
        user: sampleUser
      ),
      Account(
        name: "Cartão de Crédito",
        balance: -800.00,
        accountType: .credit,
        user: sampleUser
      ),
    ]

    for account in sampleAccounts {
      try await createAccount(account)
    }

    // Create sample transactions
    if let checkingAccount = accounts.first(where: {
      $0.accountType == .checking
    }) {
      let sampleTransactions = [
        Transaction(
          amount: 5000.00,
          description: "Salário",
          date: Calendar.current.date(byAdding: .day, value: -5, to: Date())
            ?? Date(),
          category: .salary,
          type: .income,
          account: checkingAccount
        ),
        Transaction(
          amount: -120.50,
          description: "Supermercado",
          date: Calendar.current.date(byAdding: .day, value: -3, to: Date())
            ?? Date(),
          category: .food,
          type: .expense,
          account: checkingAccount
        ),
      ]

      for transaction in sampleTransactions {
        try await createTransaction(transaction)
      }
    }

    // Create sample budgets
    let currentDate = Date()
    let calendar = Calendar.current
    let month = calendar.component(.month, from: currentDate)
    let year = calendar.component(.year, from: currentDate)

    let sampleBudgets = [
      Budget(
        category: .food,
        limit: 800.00,
        spent: 120.50,
        month: month,
        year: year,
        user: sampleUser
      ),
      Budget(
        category: .transport,
        limit: 300.00,
        spent: 0.00,
        month: month,
        year: year,
        user: sampleUser
      ),
    ]

    for budget in sampleBudgets {
      try await createBudget(budget)
    }
  }

  func clearAllData() async throws {
    try await simulateNetworkDelay()

    if shouldThrowErrors {
      throw DataServiceError.saveOperationFailed(
        NSError(domain: "MockError", code: 1)
      )
    }

    users.removeAll()
    accounts.removeAll()
    transactions.removeAll()
    budgets.removeAll()
  }

  // MARK: - Private Methods
  private func simulateNetworkDelay() async throws {
    if networkDelay > 0 {
      try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
    }
  }

  private func setupMockData() {
    // Setup is done via generateSampleData when needed
  }
}

// MARK: - Missing Protocol Definition
// Se DataServiceProtocol não existir, adicione esta definição:


