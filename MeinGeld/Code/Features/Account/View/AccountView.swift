//
//  AccountView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 13/07/25.
//

import SwiftData
import SwiftUI

struct AccountsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var allAccounts: [Account]
  @State private var showingAddAccount = false

  private let authManager = AuthenticationManager.shared
  private let firebaseService = FirebaseService.shared

  private var accounts: [Account] {
    guard let currentUser = authManager.currentUser else { return [] }
    return allAccounts.filter { $0.user.id == currentUser.id }
  }

  var body: some View {
    NavigationView {
      Group {
        if accounts.isEmpty {
          AccountsPlaceholderView(showingAddAccount: $showingAddAccount)
        } else {
          List {
            ForEach(accounts, id: \.id) { account in
              AccountRowView(account: account)
            }
            .onDelete(perform: deleteAccounts)
          }
        }
      }
      .navigationTitle("Contas")
      .toolbar {
        if !accounts.isEmpty {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Adicionar") {
              showingAddAccount = true
            }
          }
        }
      }
      .sheet(isPresented: $showingAddAccount) {
        AddAccountView()
      }
      .onAppear {
        firebaseService.logEvent(.accountsViewed)
      }
    }
  }

  private func deleteAccounts(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        let account = accounts[index]

        // Analytics - conta deletada
        firebaseService.logEvent(
          AnalyticsEvent(
            name: "account_deleted",
            parameters: [
              "account_type": account.accountType.rawValue
            ]
          )
        )

        modelContext.delete(account)
      }

      do {
        try modelContext.save()
      } catch {
        ErrorManager.shared.handle(
          error,
          context: "AccountsView.deleteAccounts"
        )
      }
    }
  }
}
// Sources/Views/AccountRowView.swift
struct AccountRowView: View {
  let account: Account

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(account.name)
          .font(.headline)

        Text(account.accountType.displayName)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Text(account.balance.formatted(.currency(code: "BRL")))
        .font(.subheadline)
        .fontWeight(.bold)
        .foregroundColor(account.balance >= 0 ? .green : .red)
    }
    .padding(.vertical, 4)
  }
}

struct AddAccountView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var initialBalance = ""
  @State private var selectedAccountType = AccountType.checking
  @State private var showingAlert = false
  @State private var alertMessage = ""

  private let authManager = AuthenticationManager.shared
  private let firebaseService = FirebaseService.shared

  var body: some View {
    NavigationView {
      Form {
        Section("Informações da Conta") {
          TextField("Nome da conta", text: $name)
            .textContentType(.organizationName)

          TextField("Saldo inicial", text: $initialBalance)
            .keyboardType(.decimalPad)

          Picker("Tipo de conta", selection: $selectedAccountType) {
            ForEach(AccountType.allCases, id: \.self) { type in
              Text(type.displayName).tag(type)
            }
          }
        }

        Section {
          Text(
            "Você pode adicionar múltiplas contas para organizar melhor suas finanças."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Nova Conta")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancelar") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Salvar") {
            saveAccount()
          }
          .disabled(name.isEmpty)
        }
      }
      .alert("Erro", isPresented: $showingAlert) {
        Button("OK") {}
      } message: {
        Text(alertMessage)
      }
    }
  }

  private func saveAccount() {
    guard let currentUser = authManager.currentUser else {
      showAlert("Usuário não encontrado")
      return
    }

    let balanceValue = Decimal(string: initialBalance) ?? 0

    let account = Account(
      name: name,
      balance: balanceValue,
      accountType: selectedAccountType,
      user: currentUser
    )

    modelContext.insert(account)

    do {
      try modelContext.save()

      // Analytics - conta criada
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "account_created",
          parameters: [
            "account_type": selectedAccountType.rawValue,
            "initial_balance": balanceValue.doubleValue,
          ]
        )
      )

      dismiss()
    } catch {
      ErrorManager.shared.handle(error, context: "AddAccountView.saveAccount")
      showAlert("Erro ao salvar conta")
    }
  }

  private func showAlert(_ message: String) {
    alertMessage = message
    showingAlert = true
  }
}
