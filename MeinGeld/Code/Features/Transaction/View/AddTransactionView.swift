//
//  AddTransactionView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import SwiftData
import SwiftUI

struct AddTransactionView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dependencies) private var container
  @Bindable var viewModel: TransactionViewModel

  @State private var amount = ""
  @State private var description = ""
  @State private var selectedCategory = TransactionCategory.other
  @State private var selectedType = TransactionType.expense
  @State private var selectedAccount: Account?
  @State private var accounts: [Account] = []
  @State private var isLoading = false

  var body: some View {
    NavigationView {
      Form {
        Section("Detalhes da Transação") {
          TextField("Valor", text: $amount)
            .keyboardType(.decimalPad)

          TextField("Descrição", text: $description)

          Picker("Tipo", selection: $selectedType) {
            ForEach(TransactionType.allCases, id: \.self) { type in
              Text(type.displayName).tag(type)
            }
          }
          .pickerStyle(.segmented)

          Picker("Categoria", selection: $selectedCategory) {
            ForEach(TransactionCategory.allCases, id: \.self) { category in
              Label(category.displayName, systemImage: category.iconName)
                .tag(category)
            }
          }

          Picker("Conta", selection: $selectedAccount) {
            Text("Selecione uma conta").tag(nil as Account?)
            ForEach(accounts, id: \.id) { account in
              Text(account.name).tag(account as Account?)
            }
          }
        }
      }
      .navigationTitle("Nova Transação")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancelar") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Salvar") {
            saveTransaction()
          }
          .disabled(!isFormValid || isLoading)
        }
      }
      .task {
        await loadAccounts()
      }
    }
  }

  private var isFormValid: Bool {
    !amount.isEmpty && !description.isEmpty && Decimal(string: amount) != nil
      && (Decimal(string: amount) ?? 0) > 0
  }

  private func loadAccounts() async {
    guard let user = container.authManager.currentUser else { return }

    do {
      accounts = try await container.dataService.fetchAccounts(for: user)
      selectedAccount = accounts.first
    } catch {
      print("Failed to load accounts: \(error)")
    }
  }

  private func saveTransaction() {
    guard let amountValue = Decimal(string: amount) else { return }

    isLoading = true

    Task {
      await viewModel.addTransaction(
        amount: amountValue,
        description: description,
        category: selectedCategory,
        type: selectedType,
        account: selectedAccount
      )

      isLoading = false

      if viewModel.errorMessage == nil {
        dismiss()
      }
    }
  }
}
