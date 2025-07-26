//
//  BudgetPlaceHolderScreen.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct BudgetPlaceholderView: View {
  @Binding var showingAddBudget: Bool

  var body: some View {
    EmptyStateView(
      icon: "chart.pie.fill",
      iconColor: .green,
      title: "Comece a planejar seu orçamento",
      description:
        "Defina limites de gastos por categoria e acompanhe quanto você está gastando em cada área",
      buttonTitle: "Criar primeiro orçamento",
      buttonColor: .green
    ) {
      showingAddBudget = true
    }
  }
}
