//
//  TransactionPlaceHolderView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct TransactionPlaceholderView: View {
  @Binding var showingAddTransaction: Bool

  private let tips = [
    "Registre tanto receitas quanto despesas",
    "Use categorias para organizar seus gastos",
    "Associe transações às suas contas",
    "Revise regularmente seus hábitos financeiros",
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        Spacer(minLength: 80)

        // Estado vazio principal
        VStack(spacing: 24) {
          Image(systemName: "list.bullet.rectangle.portrait")
            .font(.system(size: 80))
            .foregroundColor(.orange)
            .opacity(0.7)

          VStack(spacing: 16) {
            Text("Suas transações aparecerão aqui")
              .font(.title2)
              .fontWeight(.semibold)
              .multilineTextAlignment(.center)

            Text(
              "Registre suas receitas e despesas para acompanhar para onde está indo seu dinheiro"
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
          }

          Button(action: {
            showingAddTransaction = true
          }) {
            HStack {
              Image(systemName: "plus.circle.fill")
              Text("Adicionar primeira transação")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(10)
          }
        }

        // Dicas de uso
        OnboardingTipView(tips: tips)

        Spacer(minLength: 80)
      }
    }
  }
}
