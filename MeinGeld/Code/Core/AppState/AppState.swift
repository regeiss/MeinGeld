//
//  AppState.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftUI

// Estado global da aplicação
@MainActor
@Observable
final class AppState {
  // User State
  var currentUser: User?
  var isAuthenticated: Bool { currentUser != nil }

  // Loading States
  var isAuthenticating = false
  var isLoadingTransactions = false
  var isLoadingAccounts = false

  // Error States
  var authError: AppError?
  var transactionError: AppError?
  var accountError: AppError?

  // Data
  var transactions: [Transaction] = []
  var accounts: [Account] = []
  var budgets: [Budget] = []

  // Methods
  func clearErrors() {
    authError = nil
    transactionError = nil
    accountError = nil
  }

  func setLoading(_ loading: Bool, for operation: LoadingOperation) {
    switch operation {
    case .authentication:
      isAuthenticating = loading
    case .transactions:
      isLoadingTransactions = loading
    case .accounts:
      isLoadingAccounts = loading
    }
  }
}

enum LoadingOperation {
  case authentication
  case transactions
  case accounts
}
//
//// ViewModels simplificados usando AppState
//@MainActor
//final class TransactionViewModel {
//    private let appState: AppState
//    private let transactionService: TransactionServiceProtocol
//
//    init(appState: AppState, transactionService: TransactionServiceProtocol) {
//        self.appState = appState
//        self.transactionService = transactionService
//    }
//
//    func loadTransactions() async {
//        appState.setLoading(true, for: .transactions)
//
//        do {
//            appState.transactions = try await transactionService.fetchTransactions()
//            appState.transactionError = nil
//        } catch {
//            appState.transactionError = error as? AppError ?? .unknown(underlying: error)
//        }
//
//        appState.setLoading(false, for: .transactions)
//    }
//}
//
//// Uso em Views
//struct TransactionsView: View {
//    @Environment(AppState.self) private var appState
//    private let viewModel: TransactionViewModel
//
//    init(viewModel: TransactionViewModel) {
//        self.viewModel = viewModel
//    }
//
//    var body: some View {
//        NavigationView {
//            List {
//                if appState.isLoadingTransactions {
//                    ProgressView("Carregando...")
//                } else {
//                    ForEach(appState.transactions) { transaction in
//                        TransactionRowView(transaction: transaction)
//                    }
//                }
//            }
//            .alert("Erro", isPresented: .constant(appState.transactionError != nil)) {
//                Button("OK") { appState.clearErrors() }
//            } message: {
//                if let error = appState.transactionError {
//                    Text(error.localizedDescription)
//                }
//            }
//        }
//        .task { await viewModel.loadTransactions() }
//    }
//}
