//
//  TransactionsFilterView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import SwiftUI

struct TransactionFiltersView: View {
  @Bindable var viewModel: TransactionViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        Section("Filtrar por Categoria") {
          ForEach(TransactionCategory.allCases, id: \.self) { category in
            Button(action: {
              Task {
                await viewModel.filterTransactions(by: category)
                dismiss()
              }
            }) {
              Label(category.displayName, systemImage: category.iconName)
            }
          }
        }

        Section {
          Button("Limpar Filtros") {
            Task {
              await viewModel.clearFilters()
              dismiss()
            }
          }
          .foregroundColor(.blue)
        }
      }
      .navigationTitle("Filtros")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Fechar") {
            dismiss()
          }
        }
      }
    }
  }
}

#if DEBUG
  // MARK: - Preview Support
//  struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//      ContentView()
//        .inject(MockDependencyContainer())
//    }
//  }
//
//  struct DashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//      DashboardView()
//        .inject(MockDependencyContainer())
//    }
//  }
//
//  struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//      TransactionsView()
//        .inject(MockDependencyContainer())
//    }
//  }
#endif
