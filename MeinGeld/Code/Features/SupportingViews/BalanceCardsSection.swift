//
//  BalanceCardsSection.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import SwiftUI

struct BalanceCardsSection: View {
  @Bindable var viewModel: DashboardViewModel

  var body: some View {
    VStack(spacing: 16) {
      // Total Balance
      Card {
        VStack {
          Text("Saldo Total")
            .font(.headline)
            .foregroundColor(.secondary)

          Text(viewModel.totalBalance.formatted(.currency(code: "BRL")))
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(viewModel.totalBalance >= 0 ? .green : .red)
        }
      }

      // Monthly Summary
      HStack(spacing: 16) {
        Card {
          VStack(alignment: .leading) {
            Text("Receitas")
              .font(.caption)
              .foregroundColor(.secondary)

            Text(viewModel.monthlyIncome.formatted(.currency(code: "BRL")))
              .font(.headline)
              .foregroundColor(.green)
          }
        }

        Card {
          VStack(alignment: .leading) {
            Text("Despesas")
              .font(.caption)
              .foregroundColor(.secondary)

            Text(viewModel.monthlyExpenses.formatted(.currency(code: "BRL")))
              .font(.headline)
              .foregroundColor(.red)
          }
        }
      }
    }
  }
}
