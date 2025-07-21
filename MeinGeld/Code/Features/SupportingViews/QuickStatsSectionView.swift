//
//  QuickStatsSectionView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import SwiftUI

struct QuickStatsSection: View {
  @Bindable var viewModel: DashboardViewModel

  var body: some View {
    Card {
      VStack(alignment: .leading, spacing: 12) {
        Text("Resumo do Mês")
          .font(.headline)

        HStack {
          VStack(alignment: .leading) {
            Text("Economia")
              .font(.caption)
              .foregroundColor(.secondary)

            Text(viewModel.monthlySavings.formatted(.currency(code: "BRL")))
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundColor(viewModel.monthlySavings >= 0 ? .green : .red)
          }

          Spacer()

          VStack(alignment: .trailing) {
            Text("Taxa de Economia")
              .font(.caption)
              .foregroundColor(.secondary)

            Text("\(viewModel.savingsRate, specifier: "%.1f")%")
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundColor(viewModel.savingsRate >= 0 ? .green : .red)
          }
        }
      }
    }
  }
}
