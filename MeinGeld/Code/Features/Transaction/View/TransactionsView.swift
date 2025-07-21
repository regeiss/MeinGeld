//
//  TransactionsView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import SwiftData
import SwiftUI

struct TransactionsView: View {
  @Environment(\.dependencies) private var container
  @State private var viewModel: TransactionViewModel?
  @State private var showingAddTransaction = false
  @State private var showingFilters = false

  var body: some View {
    NavigationView {
      Group {
        if let viewModel = viewModel {
          TransactionsContentView(
            viewModel: viewModel,
            showingAddTransaction: $showingAddTransaction,
            showingFilters: $showingFilters
          )
        } else {
          ProgressView("Carregando...")
        }
      }
      .navigationTitle("Transações")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(action: { showingFilters = true }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
          }

          Button(action: { showingAddTransaction = true }) {
            Image(systemName: "plus")
          }
        }
      }
    }
    .onAppear {
      setupViewModel()
    }
  }

  private func setupViewModel() {
    if viewModel == nil {
      viewModel = TransactionViewModel(
        dataService: container.dataService,
        authManager: container.authManager,
        firebaseService: container.firebaseService
      )

      Task {
        await viewModel?.loadTransactions()
      }
    }
  }
}
