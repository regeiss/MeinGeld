//
//  DataService.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import Foundation
import SwiftData

// MARK: - Concrete Data Service Implementation
@MainActor
final class DataService: DataServiceProtocol {

  // MARK: - Properties
  private let modelContainer: ModelContainer
  private let modelContext: ModelContext
  private let errorManager: ErrorManagerProtocol
  private let firebaseService: FirebaseServiceProtocol
  private let dateFormatter: DateFormatter

  // MARK: - Initialization
  init(
    errorManager: ErrorManagerProtocol? = nil,
    firebaseService: FirebaseServiceProtocol? = nil
  ) throws {
    // As MainActor, it's safe to access .shared here
    self.errorManager = errorManager ?? ErrorManager.shared
    self.firebaseService = firebaseService ?? FirebaseService.shared

    // Configura o formatter de data
    self.dateFormatter = DateFormatter()
    self.dateFormatter.dateFormat = "MMM yyyy"
    self.dateFormatter.locale = Locale(identifier: "pt_BR")

    let schema = Schema([
      Transaction.self,
      Account.self,
      Budget.self,
      User.self,
    ])

    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    do {
      self.modelContainer = try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )
      self.modelContext = modelContainer.mainContext

      errorManager?.logInfo(
        "DataService inicializado com sucesso",
        context: "DataService.init"
      )
    } catch {
      errorManager?.handle(error, context: "DataService.init")
      throw DataServiceError.containerCreationFailed(error)
    }
  }

  // MARK: - Container Management
  func getModelContainer() -> ModelContainer {
    return modelContainer
  }

  func getMainContext() -> ModelContext {
    return modelContext
  }

  func saveContext() throws {
    do {
      try modelContext.save()
      errorManager.logInfo(
        "Contexto salvo com sucesso",
        context: "DataService.saveContext"
      )
    } catch {
      errorManager.handle(error, context: "DataService.saveContext")
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  // MARK: - User Operations
  func createUser(_ user: User) async throws {
    do {
      modelContext.insert(user)
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "user_created",
          parameters: [
            "user_id": user.id.uuidString,
            "email": user.email,
          ]
        )
      )

      errorManager.logInfo(
        "Usuário criado: \(user.email)",
        context: "DataService.createUser"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func fetchUser(by id: UUID) async throws -> User? {
    do {
      let descriptor = FetchDescriptor<User>(
        predicate: #Predicate<User> { $0.id == id }
      )
      let users = try modelContext.fetch(descriptor)
      return users.first
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchUser(by email: String) async throws -> User? {
    do {
      let descriptor = FetchDescriptor<User>(
        predicate: #Predicate<User> { $0.email == email }
      )
      let users = try modelContext.fetch(descriptor)
      return users.first
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func updateUser(_ user: User) async throws {
    do {
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "user_updated",
          parameters: [
            "user_id": user.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Usuário atualizado: \(user.email)",
        context: "DataService.updateUser"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func deleteUser(_ user: User) async throws {
    do {
      modelContext.delete(user)
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "user_deleted",
          parameters: [
            "user_id": user.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Usuário deletado: \(user.email)",
        context: "DataService.deleteUser"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  // MARK: - Account Operations
  func createAccount(_ account: Account) async throws {
    do {
      modelContext.insert(account)
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_created",
          parameters: [
            "account_type": account.accountType.rawValue,
            "user_id": account.user.id.uuidString,
          ]
        )
      )

      errorManager.logInfo(
        "Conta criada: \(account.name)",
        context: "DataService.createAccount"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func fetchAccounts(for user: User) async throws -> [Account] {
    do {
      let userID = user.id
      let descriptor = FetchDescriptor<Account>(
        predicate: #Predicate<Account> { account in
          account.isActive && account.user.id == userID
        },
        sortBy: [SortDescriptor(\.name)]
      )
      return try modelContext.fetch(descriptor)
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func updateAccount(_ account: Account) async throws {
    do {
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_updated",
          parameters: [
            "account_id": account.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Conta atualizada: \(account.name)",
        context: "DataService.updateAccount"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func deleteAccount(_ account: Account) async throws {
    do {
      // Soft delete - marca como inativa ao invés de deletar
      account.isActive = false
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_deleted",
          parameters: [
            "account_id": account.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Conta deletada: \(account.name)",
        context: "DataService.deleteAccount"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  // MARK: - Transaction Operations
  func createTransaction(_ transaction: Transaction) async throws {
    do {
      modelContext.insert(transaction)

      // Atualizar saldo da conta se existe
      if let account = transaction.account {
        account.balance += transaction.amount
      }

      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent.transactionCreated(
          type: transaction.type.rawValue,
          category: transaction.category.rawValue,
          amount: abs(transaction.amount.doubleValue)
        )
      )

      errorManager.logInfo(
        "Transação criada: \(transaction.transactionDescription)",
        context: "DataService.createTransaction"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func fetchTransactions(for user: User, limit: Int? = nil, offset: Int? = nil)
    async throws -> [Transaction]
  {
    do {
      // Capture o valor antes do predicado
      let userID = user.id

      var descriptor = FetchDescriptor<Transaction>(
        predicate: #Predicate<Transaction> { transaction in
          transaction.account?.user.id == userID
        },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
      )

      if let limit = limit {
        descriptor.fetchLimit = limit
      }

      if let offset = offset {
        descriptor.fetchOffset = offset
      }

      return try modelContext.fetch(descriptor)
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchTransactions(
    for account: Account,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [Transaction] {
    do {
      // Capture o valor antes do predicado
      let accountID = account.id

      var descriptor = FetchDescriptor<Transaction>(
        predicate: #Predicate<Transaction> { transaction in
          transaction.account?.id == accountID
        },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
      )

      if let limit = limit {
        descriptor.fetchLimit = limit
      }

      if let offset = offset {
        descriptor.fetchOffset = offset
      }

      return try modelContext.fetch(descriptor)
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchTransactionsByCategory(
    _ category: TransactionCategory,
    for user: User
  ) async throws -> [Transaction] {
    do {
      // Capture valores antes do predicado
      let userID = user.id
      let targetCategory = category

      let descriptor = FetchDescriptor<Transaction>(
        predicate: #Predicate<Transaction> { transaction in
          transaction.category == targetCategory
            && transaction.account?.user.id == userID
        },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
      )
      return try modelContext.fetch(descriptor)
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchTransactionsByDateRange(
    from startDate: Date,
    to endDate: Date,
    for user: User
  ) async throws -> [Transaction] {
    do {
      // Capture todos os valores antes do predicado
      let userID = user.id
      let start = startDate
      let end = endDate

      // Quebrar em predicados menores se necessário
      let descriptor = FetchDescriptor<Transaction>(
        predicate: #Predicate<Transaction> { transaction in
          transaction.date >= start && transaction.date <= end
            && transaction.account?.user.id == userID
        },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
      )
      return try modelContext.fetch(descriptor)
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func updateTransaction(_ transaction: Transaction) async throws {
    do {
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "transaction_updated",
          parameters: [
            "transaction_id": transaction.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Transação atualizada: \(transaction.transactionDescription)",
        context: "DataService.updateTransaction"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func deleteTransaction(_ transaction: Transaction) async throws {
    do {
      // Reverter saldo da conta se existe
      if let account = transaction.account {
        account.balance -= transaction.amount
      }

      modelContext.delete(transaction)
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent.transactionDeleted(
          type: transaction.type.rawValue,
          category: transaction.category.rawValue
        )
      )

      errorManager.logInfo(
        "Transação deletada: \(transaction.transactionDescription)",
        context: "DataService.deleteTransaction"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  // MARK: - Budget Operations
  func createBudget(_ budget: Budget) async throws {
    do {
      modelContext.insert(budget)
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_created",
          parameters: [
            "category": budget.category.rawValue,
            "limit": budget.limit.doubleValue,
          ]
        )
      )

      errorManager.logInfo(
        "Orçamento criado: \(budget.category.displayName)",
        context: "DataService.createBudget"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func fetchBudgets(for user: User) async throws -> [Budget] {
    do {
      // Capture o valor antes do predicado
      let userID = user.id

      let descriptor = FetchDescriptor<Budget>(
        predicate: #Predicate<Budget> { budget in
          budget.user?.id == userID
        },
        sortBy: [SortDescriptor(\.category)]
      )
      return try modelContext.fetch(descriptor)
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchBudget(
    for category: TransactionCategory,
    month: Int,
    year: Int,
    user: User
  ) async throws -> Budget? {
    do {
      // Capture todos os valores antes do predicado
      let userID = user.id
      let targetCategory = category
      let targetMonth = month
      let targetYear = year

      let descriptor = FetchDescriptor<Budget>(
        predicate: #Predicate<Budget> { budget in
          budget.category == targetCategory && budget.month == targetMonth && budget.year == targetYear && budget.user?.id == userID
        }
      )
      let budgets = try modelContext.fetch(descriptor)
      return budgets.first
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func updateBudget(_ budget: Budget) async throws {
    do {
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_updated",
          parameters: [
            "budget_id": budget.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Orçamento atualizado: \(budget.category.displayName)",
        context: "DataService.updateBudget"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  func deleteBudget(_ budget: Budget) async throws {
    do {
      modelContext.delete(budget)
      try saveContext()

      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_deleted",
          parameters: [
            "budget_id": budget.id.uuidString
          ]
        )
      )

      errorManager.logInfo(
        "Orçamento deletado: \(budget.category.displayName)",
        context: "DataService.deleteBudget"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  // MARK: - Analytics & Reports
  func fetchTotalBalance(for user: User) async throws -> Decimal {
    do {
      let accounts = try await fetchAccounts(for: user)
      return accounts.reduce(0) { $0 + $1.balance }
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchExpensesByCategory(for user: User, month: Int, year: Int)
    async throws -> [String: Decimal]
  {
    do {
      let calendar = Calendar.current
      let startDate =
        calendar.date(from: DateComponents(year: year, month: month, day: 1))
        ?? Date()
      let endDate =
        calendar.date(byAdding: .month, value: 1, to: startDate) ?? Date()

      let transactions = try await fetchTransactionsByDateRange(
        from: startDate,
        to: endDate,
        for: user
      )
      let expenses = transactions.filter { $0.type == .expense }

      var result: [String: Decimal] = [:]
      for expense in expenses {
        let categoryName = expense.category.displayName
        let amount = expense.amount
        let absAmount: Decimal
        if amount < 0 {
          absAmount = -amount
        } else {
          absAmount = amount
        }
        let current = result[categoryName] ?? 0
        result[categoryName] = current + absAmount
      }

      return result
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  func fetchIncomeVsExpenses(for user: User, months: Int) async throws -> [(
    month: String, income: Decimal, expenses: Decimal
  )] {
    do {
      var result: [(month: String, income: Decimal, expenses: Decimal)] = []
      let calendar = Calendar.current
      let currentDate = Date()

      for i in 0..<months {
        guard
          let monthDate = calendar.date(
            byAdding: .month,
            value: -i,
            to: currentDate
          ),
          let startOfMonth = calendar.dateInterval(of: .month, for: monthDate)?
            .start,
          let endOfMonth = calendar.dateInterval(of: .month, for: monthDate)?
            .end
        else {
          continue
        }

        let transactions = try await fetchTransactionsByDateRange(
          from: startOfMonth,
          to: endOfMonth,
          for: user
        )

        let income =
          transactions
          .filter { $0.type == .income }
          .reduce(0) { $0 + $1.amount }

        let expenses =
          transactions
          .filter { $0.type == .expense }
          .reduce(0) { $0 + abs($1.amount) }

        // LINHA 461 CORRIGIDA: Usar o DateFormatter configurado
        let monthName = dateFormatter.string(from: monthDate)
        result.append((month: monthName, income: income, expenses: expenses))
      }

      return result.reversed()
    } catch {
      throw DataServiceError.fetchOperationFailed(error)
    }
  }

  // MARK: - Sample Data
  func generateSampleData() async throws {
    guard try await !hasExistingData() else {
      errorManager.logInfo(
        "Dados já existem, pulando geração",
        context: "DataService.generateSampleData"
      )
      return
    }

    do {
      let sampleUser = try await createSampleUser()
      try await createSampleAccounts(for: sampleUser)
      try await createSampleTransactions(for: sampleUser)
      try await createSampleBudgets(for: sampleUser)

      errorManager.logInfo(
        "Dados de exemplo gerados com sucesso",
        context: "DataService.generateSampleData"
      )
    } catch {
      errorManager.handle(error, context: "DataService.generateSampleData")
      throw DataServiceError.sampleDataGenerationFailed(error)
    }
  }

  func clearAllData() async throws {
    do {
      // Deletar todas as entidades em ordem
      let transactionDescriptor = FetchDescriptor<Transaction>()
      let budgetDescriptor = FetchDescriptor<Budget>()
      let accountDescriptor = FetchDescriptor<Account>()
      let userDescriptor = FetchDescriptor<User>()

      let transactions = try modelContext.fetch(transactionDescriptor)
      let budgets = try modelContext.fetch(budgetDescriptor)
      let accounts = try modelContext.fetch(accountDescriptor)
      let users = try modelContext.fetch(userDescriptor)

      transactions.forEach { modelContext.delete($0) }
      budgets.forEach { modelContext.delete($0) }
      accounts.forEach { modelContext.delete($0) }
      users.forEach { modelContext.delete($0) }

      try saveContext()

      errorManager.logInfo(
        "Todos os dados foram limpos",
        context: "DataService.clearAllData"
      )
    } catch {
      throw DataServiceError.saveOperationFailed(error)
    }
  }

  // MARK: - Private Methods
  private func hasExistingData() async throws -> Bool {
    let descriptor = FetchDescriptor<User>()
    let users = try modelContext.fetch(descriptor)
    return !users.isEmpty
  }

  private func createSampleUser() async throws -> User {
    let user = User(
      email: "demo@exemplo.com",
      name: "Usuário Demo",
      preferredCurrency: "BRL"
    )

    try await createUser(user)
    return user
  }

  private func createSampleAccounts(for user: User) async throws {
    let accounts = [
      Account(
        name: "Conta Corrente Principal",
        balance: 2500.00,
        accountType: .checking,
        user: user
      ),
      Account(
        name: "Poupança",
        balance: 15000.00,
        accountType: .savings,
        user: user
      ),
      Account(
        name: "Cartão de Crédito",
        balance: -800.00,
        accountType: .credit,
        user: user
      ),
      Account(
        name: "Investimentos",
        balance: 25000.00,
        accountType: .investment,
        user: user
      ),
    ]

    for account in accounts {
      try await createAccount(account)
    }
  }

  private func createSampleTransactions(for user: User) async throws {
    let accounts = try await fetchAccounts(for: user)

    guard
      let checkingAccount = accounts.first(where: {
        $0.accountType == .checking
      }),
      let creditAccount = accounts.first(where: { $0.accountType == .credit })
    else {
      throw DataServiceError.entityNotFound
    }

    let transactions = [
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
      Transaction(
        amount: -45.00,
        description: "Uber",
        date: Calendar.current.date(byAdding: .day, value: -2, to: Date())
          ?? Date(),
        category: .transport,
        type: .expense,
        account: creditAccount
      ),
      Transaction(
        amount: -80.00,
        description: "Cinema",
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date())
          ?? Date(),
        category: .entertainment,
        type: .expense,
        account: creditAccount
      ),
    ]

    for transaction in transactions {
      try await createTransaction(transaction)
    }
  }

  private func createSampleBudgets(for user: User) async throws {
    let currentDate = Date()
    let calendar = Calendar.current
    let month = calendar.component(.month, from: currentDate)
    let year = calendar.component(.year, from: currentDate)

    let budgets = [
      Budget(
        category: .food,
        limit: 800.00,
        spent: 120.50,
        month: month,
        year: year,
        user: user
      ),
      Budget(
        category: .transport,
        limit: 300.00,
        spent: 45.00,
        month: month,
        year: year,
        user: user
      ),
      Budget(
        category: .entertainment,
        limit: 200.00,
        spent: 80.00,
        month: month,
        year: year,
        user: user
      ),
      Budget(
        category: .shopping,
        limit: 400.00,
        spent: 0.00,
        month: month,
        year: year,
        user: user
      ),
    ]

    for budget in budgets {
      try await createBudget(budget)
    }
  }
}

