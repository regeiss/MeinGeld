//
//  BudgetPlaceHolderScreen.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct BudgetPlaceholderView: View {
  @Binding var showingAddBudget: Bool

  private let tips = [
    "Comece com categorias essenciais: alimentação, transporte",
    "Use a regra 50/30/20: necessidades, desejos, poupança",
    "Revise e ajuste seus limites mensalmente",
    "Seja realista: orçamentos muito restritivos não funcionam",
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        Spacer(minLength: 80)

        // Estado vazio principal
        VStack(spacing: 24) {
          Image(systemName: "chart.pie.fill")
            .font(.system(size: 80))
            .foregroundColor(.green)
            .opacity(0.7)

          VStack(spacing: 16) {
            Text("Comece a planejar seu orçamento")
              .font(.title2)
              .fontWeight(.semibold)
              .multilineTextAlignment(.center)

            Text(
              "Defina limites de gastos por categoria e acompanhe quanto você está gastando em cada área"
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
          }

          Button(action: {
            showingAddBudget = true
          }) {
            HStack {
              Image(systemName: "plus.circle.fill")
              Text("Criar primeiro orçamento")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(10)
          }
        }

        // Categorias populares
        BudgetCategoriesGridView()

        // Regra 50/30/20
        BudgetRuleView()

        // Dicas de uso
        OnboardingTipView(
          title: "Dicas para seu orçamento",
          tips: tips,
          iconColor: .green
        )

        Spacer(minLength: 80)
      }
    }
  }
}
struct BudgetCategoriesGridView: View {
  private let popularCategories: [TransactionCategory] = [
    .food, .transport, .entertainment, .healthcare, .shopping, .bills,
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "star.fill")
          .foregroundColor(.green)
        Text("Categorias mais usadas")
          .font(.headline)
          .fontWeight(.semibold)
      }
      .padding(.horizontal)

      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible()),
        ],
        spacing: 12
      ) {
        ForEach(popularCategories, id: \.self) { category in
          CategoryCard(category: category)
        }
      }
      .padding(.horizontal)
    }
  }
}

struct CategoryCard: View {
  let category: TransactionCategory

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: category.iconName)
        .font(.title3)
        .foregroundColor(.green)

      Text(category.displayName)
        .font(.caption2)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity)
    .background(Color(.systemGray6))
    .cornerRadius(8)
  }
}
struct BudgetRuleItem: View {
  let percentage: String
  let title: String
  let description: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Text(percentage)
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(color)
        .frame(width: 50)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)

        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(8)
  }
}

struct BudgetRuleView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "percent")
          .foregroundColor(.green)
        Text("Regra 50/30/20")
          .font(.headline)
          .fontWeight(.semibold)
      }
      .padding(.horizontal)

      VStack(spacing: 12) {
        BudgetRuleItem(
          percentage: "50%",
          title: "Necessidades",
          description: "Moradia, alimentação, transporte",
          color: .red
        )

        BudgetRuleItem(
          percentage: "30%",
          title: "Desejos",
          description: "Entretenimento, compras, lazer",
          color: .orange
        )

        BudgetRuleItem(
          percentage: "20%",
          title: "Poupança",
          description: "Reserva, investimentos, aposentadoria",
          color: .green
        )
      }
      .padding(.horizontal)
    }
  }
}
