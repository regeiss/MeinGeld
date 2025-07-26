//
//  AddBudgetScreen.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI
import SwiftData

struct AddBudgetView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var selectedCategory = TransactionCategory.food
  @State private var limitAmount = ""
  @State private var selectedMonth = Calendar.current.component(
    .month,
    from: Date()
  )
  @State private var selectedYear = Calendar.current.component(
    .year,
    from: Date()
  )
  @State private var showingAlert = false
  @State private var alertMessage = ""

  private let authManager = AuthenticationManager.shared
  private let firebaseService = FirebaseService.shared

  private let months = [
    (1, "Janeiro"), (2, "Fevereiro"), (3, "Março"), (4, "Abril"),
    (5, "Maio"), (6, "Junho"), (7, "Julho"), (8, "Agosto"),
    (9, "Setembro"), (10, "Outubro"), (11, "Novembro"), (12, "Dezembro"),
  ]

  private let years = Array(2020...2030)

  var body: some View {
    NavigationView {
      Form {
        Section("Configuração do Orçamento") {
          Picker("Categoria", selection: $selectedCategory) {
            ForEach(TransactionCategory.allCases, id: \.self) { category in
              Label(category.displayName, systemImage: category.iconName)
                .tag(category)
            }
          }

          TextField("Limite de gasto", text: $limitAmount)
            .keyboardType(.decimalPad)

          Picker("Mês", selection: $selectedMonth) {
            ForEach(months, id: \.0) { month in
              Text(month.1).tag(month.0)
            }
          }

          Picker("Ano", selection: $selectedYear) {
            ForEach(years, id: \.self) { year in
              Text(String(year)).tag(year)
            }
          }
        }

        Section {
          Text(
            "Defina um limite de gastos para esta categoria. Você será notificado quando se aproximar do limite."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Novo Orçamento")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancelar") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Salvar") {
            saveBudget()
          }
          .disabled(limitAmount.isEmpty)
        }
      }
      .alert("Erro", isPresented: $showingAlert) {
        Button("OK") {}
      } message: {
        Text(alertMessage)
      }
    }
  }

  private func saveBudget() {
    guard let currentUser = authManager.currentUser else {
      showAlert("Usuário não encontrado")
      return
    }

    guard let limit = Decimal(string: limitAmount), limit > 0 else {
      showAlert("Valor do limite inválido")
      return
    }

    let budget = Budget(
      category: selectedCategory,
      limit: limit,
      month: selectedMonth,
      year: selectedYear,
      user: currentUser
    )

    modelContext.insert(budget)

    do {
      try modelContext.save()

      // Analytics - orçamento criado
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "budget_created",
          parameters: [
            "category": selectedCategory.rawValue,
            "limit": limit.doubleValue,
            "month": selectedMonth,
            "year": selectedYear,
          ]
        )
      )

      dismiss()
    } catch {
      ErrorManager.shared.handle(error, context: "AddBudgetView.saveBudget")
      showAlert("Erro ao salvar orçamento")
    }
  }

  private func showAlert(_ message: String) {
    alertMessage = message
    showingAlert = true
  }
}
