//
//  BudgetView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 13/07/25.
//

import SwiftData
import SwiftUI

struct BudgetView: View {

  @Environment(\.modelContext) private var modelContext
  @State private var viewModel: BudgetViewModel?
  @State private var showingAddBudget = false
  @State private var showingAlert = false
  @State private var alertMessage = ""

  private let months = [
    (1, "Jan"), (2, "Fev"), (3, "Mar"), (4, "Abr"),
    (5, "Mai"), (6, "Jun"), (7, "Jul"), (8, "Ago"),
    (9, "Set"), (10, "Out"), (11, "Nov"), (12, "Dez"),
  ]

  var body: some View {
    NavigationView {
      Group {
        if let viewModel = viewModel {
          if viewModel.currentMonthBudgets.isEmpty && !viewModel.isLoading {
            BudgetPlaceholderView(showingAddBudget: $showingAddBudget)
          } else {
            budgetContent(viewModel: viewModel)
          }
        } else {
          ProgressView("Inicializando...")
        }
      }
      .navigationTitle("Orçamentos")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          if let viewModel = viewModel, !viewModel.currentMonthBudgets.isEmpty {
            monthYearButton(viewModel: viewModel)

            Button("Adicionar") {
              showingAddBudget = true
            }
          }
        }
      }
      .sheet(isPresented: $showingAddBudget) {
        if let viewModel = viewModel {
          AddBudgetView(viewModel: viewModel)
        }
      }
      .alert("Erro", isPresented: $showingAlert) {
        Button("OK") {}
      } message: {
        Text(alertMessage)
      }
      .task {
        if viewModel == nil {
          let repository = BudgetRepository(modelContext: modelContext)
          let authManager = AuthenticationManager.shared
          let errorManager = ErrorManager.shared
          viewModel = BudgetViewModel(
            repository: repository,
            authManager: authManager,
            errorManager: errorManager
          )
        }
        await viewModel?.loadBudgets()
        viewModel?.trackBudgetViewed()
      }
      .onChange(of: viewModel?.errorMessage) { _, newValue in
        if let error = newValue {
          alertMessage = error
          showingAlert = true
        }
      }
    }
  }

  @ViewBuilder
  private func monthYearButton(viewModel: BudgetViewModel)
    -> some View
  {
    Menu {
      ForEach(2020...2030, id: \.self) { year in
        Menu("\(year)") {
          ForEach(months, id: \.0) { month in
            Button("\(month.1) \(year)") {
              Task {
                await viewModel.changeMonth(to: month.0, year: year)
                viewModel.trackMonthChanged(month: month.0, year: year)
              }
            }
          }
        }
      }
    } label: {
      HStack {
        Image(systemName: "calendar")
        Text(monthYearText(viewModel: viewModel))
          .font(.caption)
      }
    }
  }

  private func monthYearText(viewModel: BudgetViewModel) -> String {
    let monthName = months.first { $0.0 == viewModel.selectedMonth }?.1 ?? "Mês"
    return "\(monthName) \(viewModel.selectedYear)"
  }

  @ViewBuilder
  private func budgetContent(viewModel: BudgetViewModel) -> some View {
    List {
      if viewModel.isLoading {
        ProgressView("Carregando orçamentos...")
          .frame(maxWidth: .infinity, alignment: .center)
      } else {
        // Seção de resumo
        if let summary = viewModel.budgetSummary {
          BudgetSummarySection(summary: summary)
        }

        // Lista de orçamentos
        Section("Orçamentos de \(monthYearText(viewModel: viewModel))") {
          ForEach(viewModel.currentMonthBudgets, id: \.id) { budget in
            BudgetRowView(budget: budget)
          }
          .onDelete { offsets in
            deleteBudgets(offsets: offsets, viewModel: viewModel)
          }
        }
      }
    }
  }

  private func deleteBudgets(
    offsets: IndexSet,
    viewModel: BudgetViewModel
  ) {
    Task {
      for index in offsets {
        let budget = viewModel.currentMonthBudgets[index]
        let success = await viewModel.deleteBudget(budget)

        if !success {
          break
        }
      }
    }
  }
}
struct BudgetRowView: View {
  let budget: Budget

  private var progressPercentage: Double {
    guard budget.limit > 0 else { return 0 }
    let spent = NSDecimalNumber(decimal: budget.spent)
    let limit = NSDecimalNumber(decimal: budget.limit)
    let percentage = spent.dividing(by: limit).doubleValue
    return min(percentage, 1.0)
  }

  private var remainingAmount: Decimal {
    budget.limit - budget.spent
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label(budget.categoryDisplayName, systemImage: budget.categoryIconName)
          .font(.headline)

        Spacer()

        Text(budget.limit.formatted(.currency(code: "BRL")))
          .font(.subheadline)
          .fontWeight(.medium)
      }

      ProgressView(value: progressPercentage)
        .progressViewStyle(
          LinearProgressViewStyle(tint: progressPercentage > 0.8 ? .red : .blue)
        )

      HStack {
        Text("Gasto: \(budget.spent.formatted(.currency(code: "BRL")))")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()

        Text("Restante: \(remainingAmount.formatted(.currency(code: "BRL")))")
          .font(.caption)
          .foregroundColor(remainingAmount >= 0 ? .green : .red)
      }
    }
    .padding(.vertical, 4)
  }
}

struct BudgetSummarySection: View {
  let summary: BudgetSummary

  var body: some View {
    Section {
      VStack(spacing: 16) {
        // Resumo principal
        HStack {
          VStack(alignment: .leading) {
            Text("Total Orçado")
              .font(.caption)
              .foregroundColor(.secondary)

            Text(summary.totalBudgeted.formatted(.currency(code: "BRL")))
              .font(.headline)
              .fontWeight(.semibold)
          }

          Spacer()

          VStack(alignment: .trailing) {
            Text("Gasto")
              .font(.caption)
              .foregroundColor(.secondary)

            Text(summary.totalSpent.formatted(.currency(code: "BRL")))
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(
                summary.totalSpent > summary.totalBudgeted ? .red : .primary
              )
          }
        }

        // Barra de progresso
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Utilização: \(Int(summary.utilizationPercentage))%")
              .font(.caption)

            Spacer()

            Text(
              "Restante: \(summary.totalRemaining.formatted(.currency(code: "BRL")))"
            )
            .font(.caption)
            .foregroundColor(summary.totalRemaining >= 0 ? .green : .red)
          }

          ProgressView(value: min(summary.utilizationPercentage / 100, 1.0))
            .progressViewStyle(
              LinearProgressViewStyle(
                tint: summary.utilizationPercentage > 100
                  ? .red : summary.utilizationPercentage > 80 ? .orange : .green
              )
            )
        }

        // Estatísticas
        if summary.overBudgetCount > 0 {
          HStack {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.red)

            Text("\(summary.overBudgetCount) orçamento(s) excedido(s)")
              .font(.caption)
              .foregroundColor(.red)

            Spacer()
          }
        }
      }
      .padding(.vertical, 8)
    }
  }
}
