//
//  AccountPlaceHolderScreen.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct AccountsPlaceholderView: View {
  @Binding var showingAddAccount: Bool

  var body: some View {
    EmptyStateView(
      icon: "creditcard.and.123",
      iconColor: .blue,
      title: "Suas contas aparecerão aqui",
      description:
        "Adicione suas contas bancárias, cartões e investimentos para começar a controlar suas finanças",
      buttonTitle: "Adicionar primeira conta",
      buttonColor: .blue
    ) {
      showingAddAccount = true
    }
  }
}
