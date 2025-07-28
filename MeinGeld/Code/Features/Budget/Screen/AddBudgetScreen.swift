//
//  AddBudgetScreen.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftData
import SwiftUI

struct AddBudgetView: View {
  @Environment(\.dismiss) private var dismiss
  @State var viewModel: BudgetViewModel

  @State private var selectedCategory = TransactionCategory.food
  @State private var limitAmount = ""
  @State private var selectedMonth: Int
  @State private var selectedYear: Int
  @State private var showingAlert = false
  @State private var alertMessage = ""

  private let months = [
    (1, "Janeiro"), (2, "Fevereiro"), (3, "Março"), (4, "Abril"),
    (5, "Maio"), (6, "Junho"), (7, "Julho"), (8, "Agosto"),
    (9, "Setembro"), (10, "Outubro"), (11, "Novembro"), (12, "Dezembro"),
  ]

  private let years = Array(2020...2030)

  init(viewModel: BudgetViewModel) {
    self.viewModel = viewModel
    self._selectedMonth = State(initialValue: viewModel.selectedMonth)
    self._selectedYear = State(initialValue: viewModel.selectedYear)
  }

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
          .disabled(limitAmount.isEmpty || viewModel.isLoading)
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
    Task {
      guard let limit = Decimal(string: limitAmount), limit > 0 else {
        alertMessage = "Valor do limite inválido"
        showingAlert = true
        return
      }

      let success = await viewModel.createBudget(
        category: selectedCategory,
        limit: limit,
        month: selectedMonth,
        year: selectedYear
      )

      if success {
        dismiss()
      } else if let error = viewModel.errorMessage {
        alertMessage = error
        showingAlert = true
      }
    }
  }
}
