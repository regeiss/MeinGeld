//
//  TransactionsContentView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftUI

struct TransactionsContentView: View {
  @Bindable var viewModel: TransactionViewModel
  @Binding var showingAddTransaction: Bool
  @Binding var showingFilters: Bool

  var body: some View {
    List {
      if viewModel.isLoading && viewModel.transactions.isEmpty {
        HStack {
          Spacer()
          ProgressView("Carregando transações...")
          Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else if viewModel.transactions.isEmpty {
        TransactionPlaceholderView(showingAddTransaction: $showingAddTransaction)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else {
        ForEach(viewModel.transactions, id: \.id) { transaction in
          TransactionRowView(transaction: transaction)
            .onAppear {
              // Load more when reaching near the end
              if transaction == viewModel.transactions.last {
                Task {
                  await viewModel.loadMoreTransactions()
                }
              }
            }
        }
        .onDelete { indexSet in
          Task {
            for index in indexSet {
              await viewModel.deleteTransaction(viewModel.transactions[index])
            }
          }
        }

        if viewModel.isLoadingMore {
          HStack {
            Spacer()
            ProgressView("Carregando mais...")
            Spacer()
          }
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }
      }
    }
    .refreshable {
      await viewModel.loadTransactions()
    }
    .sheet(isPresented: $showingAddTransaction) {
      AddTransactionView(viewModel: viewModel)
    }
    .sheet(isPresented: $showingFilters) {
      TransactionFiltersView(viewModel: viewModel)
    }
    .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
      Button("OK") {
        viewModel.errorMessage = nil
      }
    } message: {
      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
      }
    }
  }
}

