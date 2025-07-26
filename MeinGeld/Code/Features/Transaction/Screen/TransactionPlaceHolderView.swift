//
//  TransactionPlaceHolderView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct TransactionPlaceholderView: View {
  @Binding var showingAddTransaction: Bool

  var body: some View {
    EmptyStateView(
      icon: "list.bullet.rectangle.portrait",
      iconColor: .orange,
      title: "Suas transações aparecerão aqui",
      description:
        "Registre suas receitas e despesas para acompanhar para onde está indo seu dinheiro",
      buttonTitle: "Adicionar primeira transação",
      buttonColor: .orange
    ) {
      showingAddTransaction = true
    }
  }
}
