//
//  AccountView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 13/07/25.
//

import SwiftData
import SwiftUI

struct AccountView: View {

  @Environment(\.modelContext) private var modelContext
  @State private var viewModel: AccountViewModel?
  @State private var showingAddAccount = false
  @State private var showingAlert = false
  @State private var alertMessage = ""

  var body: some View {
    NavigationView {
      Group {
        if let viewModel = viewModel {
          if viewModel.accounts.isEmpty && !viewModel.isLoading {
            AccountsPlaceholderView(
              showingAddAccount: $showingAddAccount
            )
          } else {
            accountsList(viewModel: viewModel)
          }
        } else {
          ProgressView("Inicializando...")
        }
      }
      .navigationTitle("Contas")
      .toolbar {
        if let viewModel = viewModel, !viewModel.accounts.isEmpty {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Adicionar") {
              showingAddAccount = true
            }
          }
        }
      }
      .sheet(isPresented: $showingAddAccount) {
        if let viewModel = viewModel {
          AddAccountView(viewModel: viewModel)
        }
      }
      .alert("Erro", isPresented: $showingAlert) {
        Button("OK") {}
      } message: {
        Text(alertMessage)
      }
      .task {
        if viewModel == nil {
          let repository = AccountRepository(modelContext: modelContext)
          viewModel = AccountViewModel(repository: repository)
        }
        await viewModel?.loadAccounts()
        viewModel?.trackAccountViewed()
      }
      .onChange(of: viewModel?.errorMessage) { _, newValue in
        if let error = newValue {
          alertMessage = error
          showingAlert = true
        }
      }
    }
  }

  private func accountsList(viewModel: AccountViewModel) -> some View {
    List {
      if viewModel.isLoading {
        ProgressView("Carregando contas...")
          .frame(maxWidth: .infinity, alignment: .center)
      } else {
        // Seção de resumo
        Section {
          HStack {
            VStack(alignment: .leading) {
              Text("Saldo Total")
                .font(.caption)
                .foregroundColor(.secondary)

              Text(viewModel.totalBalance.formatted(.currency(code: "BRL")))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(viewModel.totalBalance >= 0 ? .green : .red)
            }

            Spacer()

            VStack(alignment: .trailing) {
              Text("Contas")
                .font(.caption)
                .foregroundColor(.secondary)

              Text("\(viewModel.accounts.count)")
                .font(.title2)
                .fontWeight(.semibold)
            }
          }
          .padding(.vertical, 8)
        }

        // Lista de contas
        Section("Suas Contas") {
          ForEach(viewModel.accounts, id: \.id) { account in
            AccountRowView(account: account, viewModel: viewModel)
          }
          .onDelete { offsets in
            deleteAccounts(offsets: offsets, viewModel: viewModel)
          }
        }
      }
    }
  }

  private func deleteAccounts(
    offsets: IndexSet,
    viewModel: AccountViewModel
  ) {
    Task {
      for index in offsets {
        let account = viewModel.accounts[index]
        let success = await viewModel.deleteAccount(account)

        if !success {
          // O erro já é tratado no ViewModel
          break
        }
      }
    }
  }
}

// Sources/Views/AccountRowView.swift
struct AccountRowView: View {
  let account: Account
  let viewModel: AccountViewModel

  var body: some View {
    HStack {
      // Ícone do tipo de conta
      Image(systemName: iconForAccountType(account.accountType))
        .font(.title2)
        .foregroundColor(colorForAccountType(account.accountType))
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 4) {
        Text(account.name)
          .font(.headline)

        Text(account.accountType.displayName)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        Text(account.balance.formatted(.currency(code: "BRL")))
          .font(.subheadline)
          .fontWeight(.bold)
          .foregroundColor(account.balance >= 0 ? .green : .red)

        if account.accountType == .credit && account.balance < 0 {
          Text("Fatura")
            .font(.caption2)
            .foregroundColor(.red)
        }
      }
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
    .onTapGesture {
      viewModel.trackAccountInteraction(
        action: "tap",
        accountType: account.accountType
      )
    }
  }

  private func iconForAccountType(_ type: AccountType) -> String {
    switch type {
    case .checking: return "building.columns.fill"
    case .savings: return "banknote.fill"
    case .credit: return "creditcard.fill"
    case .investment: return "chart.line.uptrend.xyaxis"
    }
  }

  private func colorForAccountType(_ type: AccountType) -> Color {
    switch type {
    case .checking: return .blue
    case .savings: return .green
    case .credit: return .orange
    case .investment: return .purple
    }
  }
}

struct AddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: AccountViewModel

  @State private var name = ""
  @State private var initialBalance = ""
  @State private var selectedAccountType = AccountType.checking
  @State private var showingAlert = false
  @State private var alertMessage = ""

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
              Label(type.displayName, systemImage: iconForAccountType(type))
                .tag(type)
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
          .disabled(name.isEmpty || viewModel.isLoading)
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
    Task {
      let balanceValue = Decimal(string: initialBalance) ?? 0

      let success = await viewModel.createAccount(
        name: name,
        initialBalance: balanceValue,
        accountType: selectedAccountType
      )

      if success {
        dismiss()
      } else if let error = viewModel.errorMessage {
        alertMessage = error
        showingAlert = true
      }
    }
  }

  private func iconForAccountType(_ type: AccountType) -> String {
    switch type {
    case .checking: return "building.columns.fill"
    case .savings: return "banknote.fill"
    case .credit: return "creditcard.fill"
    case .investment: return "chart.line.uptrend.xyaxis"
    }
  }
}

struct AccountTypesGridView: View {
  private let accountTypes = AccountType.allCases

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "info.circle.fill")
          .foregroundColor(.blue)
        Text("Tipos de conta disponíveis")
          .font(.headline)
          .fontWeight(.semibold)
      }
      .padding(.horizontal)

      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
        ],
        spacing: 12
      ) {
        ForEach(accountTypes, id: \.self) { type in
          AccountTypeCard(accountType: type)
        }
      }
      .padding(.horizontal)
    }
  }
}

struct AccountTypeCard: View {
  let accountType: AccountType

  private var icon: String {
    switch accountType {
    case .checking: return "building.columns.fill"
    case .savings: return "banknote.fill"
    case .credit: return "creditcard.fill"
    case .investment: return "chart.line.uptrend.xyaxis"
    }
  }

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)

      Text(accountType.displayName)
        .font(.caption)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color(.systemGray6))
    .cornerRadius(8)
  }
}
