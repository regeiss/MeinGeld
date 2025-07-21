//
//  AccountSecurityView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import LocalAuthentication
import SwiftUI
import Firebase

struct AccountSecurityView: View {
  @StateObject private var biometricService = BiometricAuthService()
  @StateObject private var emailService = EmailVerificationService(authManager: AuthenticationManager, firebaseService: any FirebaseServiceProtocol as! FirebaseServiceProtocol)
  @State private var biometricEnabled = UserDefaults.standard.bool(
    forKey: "biometric_enabled"
  )
  @State private var showingDeleteConfirmation = false
  @State private var isDeleting = false

  private let authManager = AuthenticationManager.shared

  var body: some View {
    List {
      // Email Verification Section
      Section("Verificação de Email") {
        HStack {
          Image(
            systemName: emailService.isEmailVerified
              ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
          )
          .foregroundColor(emailService.isEmailVerified ? .green : .orange)

          VStack(alignment: .leading) {
            Text(
              emailService.isEmailVerified
                ? "Email verificado" : "Email não verificado"
            )
            .fontWeight(.medium)

            if !emailService.isEmailVerified {
              Text("Verifique seu email para maior segurança")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          Spacer()

          if !emailService.isEmailVerified {
            Button(action: resendVerificationEmail) {
              if emailService.isCheckingVerification {
                ProgressView()
                  .scaleEffect(0.8)
              } else if emailService.resendCooldown > 0 {
                Text("\(Int(emailService.resendCooldown))s")
                  .font(.caption)
                  .foregroundColor(.secondary)
              } else {
                Text("Reenviar")
                  .font(.caption)
                  .foregroundColor(.blue)
              }
            }
            .disabled(
              emailService.resendCooldown > 0
                || emailService.isCheckingVerification
            )
          }
        }
      }

      // Biometric Authentication Section
      if biometricService.isAvailable {
        Section("Autenticação Biométrica") {
          HStack {
            Image(systemName: biometricIconName)
              .foregroundColor(.blue)

            VStack(alignment: .leading) {
              Text("Usar \(biometricTypeName)")
                .fontWeight(.medium)

              Text("Acesso rápido e seguro ao app")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $biometricEnabled)
              .onChange(of: biometricEnabled) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "biometric_enabled")
              }
          }
        }
      }

      // Password Management Section
      Section("Gerenciar Senha") {
        NavigationLink(destination: ChangePasswordView()) {
          Label("Alterar Senha", systemImage: "key.fill")
        }

        Button(action: sendPasswordReset) {
          Label("Enviar Reset de Senha", systemImage: "envelope.fill")
            .foregroundColor(.blue)
        }
      }

      // Danger Zone
      Section("Zona de Perigo") {
        Button(action: { showingDeleteConfirmation = true }) {
          Label("Excluir Conta", systemImage: "trash.fill")
            .foregroundColor(.red)
        }
      }
    }
    .navigationTitle("Segurança da Conta")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      emailService.checkEmailVerification()
    }
    .alert("Confirmar Exclusão", isPresented: $showingDeleteConfirmation) {
      Button("Cancelar", role: .cancel) {}
      Button("Excluir", role: .destructive) {
        deleteAccount()
      }
    } message: {
      Text(
        "Esta ação não pode ser desfeita. Todos os seus dados serão permanentemente removidos."
      )
    }
  }

  private var biometricIconName: String {
    switch biometricService.biometricType {
    case .faceID: return "faceid"
    case .touchID: return "touchid"
    case .opticID: return "opticid"
    default: return "person.badge.key.fill"
    }
  }

  private var biometricTypeName: String {
    switch biometricService.biometricType {
    case .faceID: return "Face ID"
    case .touchID: return "Touch ID"
    case .opticID: return "Optic ID"
    default: return "Biometria"
    }
  }

  private func resendVerificationEmail() {
    Task {
      do {
        try await emailService.resendVerificationEmail()
      } catch {
        print("Failed to resend verification email: \(error)")
      }
    }
  }

  private func sendPasswordReset() {
    guard let email = authManager.currentUser?.email else { return }

    Task {
      do {
        try await authManager.resetPassword(email: email)
      } catch {
        print("Failed to send password reset: \(error)")
      }
    }
  }

  private func deleteAccount() {
    isDeleting = true

    Task {
      do {
        try await authManager.deleteAccount()
      } catch {
        print("Failed to delete account: \(error)")
        isDeleting = false
      }
    }
  }
}
