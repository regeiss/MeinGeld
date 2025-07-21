//
//  BudgetViewModel.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class BudgetViewModel {
    
    // MARK: - Published Properties
    var budgets: [Budget] = []
    var expensesByCategory: [String: Decimal] = [:]
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
    func loadBudgets() async {
        guard let user = authManager.currentUser else {
            errorMessage = "Usuário não autenticado"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            budgets = try await dataService.fetchBudgets(for: user)
            
            // Load current month expenses
            let currentDate = Date()
            let calendar = Calendar.current
            let month = calendar.component(.month, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            
            expensesByCategory = try await dataService.fetchExpensesByCategory(
                for: user,
                month: month,
                year: year
            )
            
            firebaseService.logEvent(.budgetViewed)
            
        } catch {
            errorMessage = error.localizedDescription
            budgets = []
            expensesByCategory = [:]
        }
        
        isLoading = false
    }
    
    func createBudget(
        category: TransactionCategory,
        limit: Decimal
    ) async {
        guard let user = authManager.currentUser,
              limit > 0 else {
            errorMessage = "Dados inválidos"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let currentDate = Date()
            let calendar = Calendar.current
            let month = calendar.component(.month, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            
            let budget = Budget(
                category: category,
                limit: limit,
                spent: 0,
                month: month,
                year: year,
                user: user
            )
            
            try await dataService.createBudget(budget)
            
            // Refresh budgets
            await loadBudgets()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateBudget(_ budget: Budget) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataService.updateBudget(budget)
            
            // Update local array
            if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
                budgets[index] = budget
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteBudget(_ budget: Budget) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await dataService.deleteBudget(budget)
            
            // Remove from local array
            budgets.removeAll { $0.id == budget.id }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func getBudgetProgress(for category: TransactionCategory) -> Double {
        guard let budget = budgets.first(where: { $0.category == category }),
              budget.limit > 0 else {
            return 0.0
        }
        
        let spent = expensesByCategory[category.displayName] ?? 0
        return min(spent.doubleValue / budget.limit.doubleValue, 1.0)
    }
    
    func isOverBudget(for category: TransactionCategory) -> Bool {
        guard let budget = budgets.first(where: { $0.category == category }) else {
            return false
        }
        
        let spent = expensesByCategory[category.displayName] ?? 0
        return spent > budget.limit
    }
}
