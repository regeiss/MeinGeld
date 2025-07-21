//
//  RecentTransactionsView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import SwiftUI

struct RecentTransactionsSection: View {
  @Bindable var viewModel: DashboardViewModel

  var body: some View {
    Card {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Transações Recentes")
            .font(.headline)

          Spacer()

          NavigationLink("Ver todas", destination: TransactionsView())
            .font(.caption)
            .foregroundColor(.blue)
        }

        if viewModel.recentTransactions.isEmpty {
          Text("Nenhuma transação recente")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical)
        } else {
          ForEach(viewModel.recentTransactions, id: \.id) { transaction in
            TransactionRowView(transaction: transaction)
          }
        }
      }
    }
  }
}
