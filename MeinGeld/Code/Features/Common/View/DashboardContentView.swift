//
//  DashboardContentView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftUI

struct DashboardContentView: View {
  @Bindable var viewModel: DashboardViewModel

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        if viewModel.isLoading {
          ProgressView("Carregando dados...")
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
          // Welcome Message
          WelcomeSection()

          // Balance Cards
          BalanceCardsSection(viewModel: viewModel)

          // Quick Stats
          QuickStatsSection(viewModel: viewModel)

          // Recent Transactions
          RecentTransactionsSection(viewModel: viewModel)

          // Accounts Summary
          AccountsSummarySection(viewModel: viewModel)
        }
      }
      .padding()
    }
    .refreshable {
      await viewModel.refreshData()
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
