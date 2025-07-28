//
//  AccountPlaceHolderScreen.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct AccountsPlaceholderView: View {
  @Binding var showingAddAccount: Bool

  private let tips = [
    "Adicione todas suas contas: corrente, poupança, cartões",
    "Mantenha os saldos atualizados para controle preciso",
    "Separe contas pessoais das empresiais",
    "Use nomes descritivos: 'Nubank Roxo', 'Itaú Corrente'",
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        Spacer(minLength: 80)

        // Estado vazio principal
        VStack(spacing: 24) {
          Image(systemName: "creditcard.and.123")
            .font(.system(size: 80))
            .foregroundColor(.blue)
            .opacity(0.7)

          VStack(spacing: 16) {
            Text("Suas contas aparecerão aqui")
              .font(.title2)
              .fontWeight(.semibold)
              .multilineTextAlignment(.center)

            Text(
              "Adicione suas contas bancárias, cartões e investimentos para começar a controlar suas finanças"
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
          }

          Button(action: {
            showingAddAccount = true
          }) {
            HStack {
              Image(systemName: "plus.circle.fill")
              Text("Adicionar primeira conta")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(10)
          }
        }

        // Tipos de conta disponíveis
        AccountTypesGridView()

        // Dicas de uso
        OnboardingTipView(
          title: "Dicas para suas contas",
          tips: tips,
          iconColor: .blue
        )

        Spacer(minLength: 80)
      }
    }
  }
}
