//
//  AccountSecurityView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Firebase
import Foundation
import LocalAuthentication
import SwiftUI

//
//  AccountSecurityView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss
//

struct AccountSecurityView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var currentPassword = ""
  @State private var newPassword = ""
  @State private var confirmPassword = ""
  @State private var showingAlert = false
  @State private var alertMessage = ""
  @State private var isLoading = false

  private let authManager = AuthenticationManager.shared
  private let firebaseService = FirebaseService.shared

  var body: some View {
    NavigationView {
      Form {
        Section("Alterar Senha") {
          SecureField("Senha atual", text: $currentPassword)
            .textContentType(.password)

          SecureField("Nova senha", text: $newPassword)
            .textContentType(.newPassword)

          SecureField("Confirmar nova senha", text: $confirmPassword)
            .textContentType(.newPassword)
        }

        Section("Autenticação") {
          NavigationLink(destination: Text("Autenticação em dois fatores")) {
            Label("Autenticação em 2 fatores", systemImage: "lock.shield")
          }

          NavigationLink(destination: Text("Dispositivos conectados")) {
            Label("Dispositivos conectados", systemImage: "iphone")
          }
        }

        Section("Privacidade") {
          NavigationLink(destination: Text("Dados pessoais")) {
            Label(
              "Gerenciar dados pessoais",
              systemImage: "person.text.rectangle"
            )
          }

          Button(action: exportData) {
            Label("Exportar dados", systemImage: "square.and.arrow.up")
          }
        }

        Section {
          Button("Salvar alterações") {
            changePassword()
          }
          .disabled(!isFormValid || isLoading)
          .frame(maxWidth: .infinity)
          .foregroundColor(isFormValid ? .blue : .gray)
        }
      }
      .navigationTitle("Segurança da Conta")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancelar") {
            dismiss()
          }
        }
      }
      .alert("Erro", isPresented: $showingAlert) {
        Button("OK") {}
      } message: {
        Text(alertMessage)
      }
    }
  }

  private var isFormValid: Bool {
    !currentPassword.isEmpty && !newPassword.isEmpty
      && newPassword == confirmPassword && newPassword.count >= 6
  }

  private func changePassword() {
    guard isFormValid else {
      showAlert("Por favor, preencha todos os campos corretamente")
      return
    }

    isLoading = true

    Task {
      do {
        // Aqui você implementaria a lógica de mudança de senha
        // try await authManager.changePassword(current: currentPassword, new: newPassword)

        // Analytics
        firebaseService.logEvent(.passwordChanged)

        await MainActor.run {
          isLoading = false
          dismiss()
        }
      } catch {
        await MainActor.run {
          isLoading = false
          showAlert(error.localizedDescription)
        }
      }
    }
  }

  private func exportData() {
    firebaseService.logEvent(.dataExportRequested)
    // Implementar exportação de dados
  }

  private func showAlert(_ message: String) {
    alertMessage = message
    showingAlert = true
  }
}

// MARK: - Analytics Extensions
extension AnalyticsEvent {
//  static let passwordChanged = AnalyticsEvent(name: "password_changed")
  static let dataExportRequested = AnalyticsEvent(name: "data_export_requested")
}
