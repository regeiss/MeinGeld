//
//  AccountsSummarySectionView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import SwiftUI

struct AccountsSummarySection: View {
  @Bindable var viewModel: DashboardViewModel

  var body: some View {
    Card {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Contas")
            .font(.headline)

          Spacer()

          NavigationLink("Ver todas", destination: AccountsView())
            .font(.caption)
            .foregroundColor(.blue)
        }

        ForEach(viewModel.topAccounts, id: \.id) { account in
          HStack {
            Text(account.name)
              .font(.subheadline)

            Spacer()

            Text(account.balance.formatted(.currency(code: "BRL")))
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(account.balance >= 0 ? .green : .red)
          }
        }
      }
    }
  }
}
