//
//  ForgotPasswordView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import SwiftUI

struct ForgotPasswordView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var email = ""
  @State private var isLoading = false
  @State private var showingSuccess = false
  @State private var showingError = false
  @State private var errorMessage = ""

  private let authManager = AuthenticationManager.shared

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 12) {
          Image(systemName: "lock.rotation")
            .font(.system(size: 60))
            .foregroundColor(.blue)

          Text("Recuperar Senha")
            .font(.title2)
            .fontWeight(.bold)

          Text("Digite seu email e enviaremos um link para redefinir sua senha")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }

        // Email Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Email")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Digite seu email", text: $email)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
        }

        // Send Button
        Button(action: sendResetEmail) {
          HStack {
            if isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            } else {
              Text("Enviar Link de Recuperação")
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity, minHeight: 50)
          .background(isFormValid ? Color.blue : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(10)
        }
        .disabled(!isFormValid || isLoading)

        Spacer()
      }
      .padding()
      .navigationTitle("Recuperar Senha")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Fechar") {
            dismiss()
          }
        }
      }
      .alert("Email Enviado", isPresented: $showingSuccess) {
        Button("OK") {
          dismiss()
        }
      } message: {
        Text(
          "Verifique sua caixa de entrada e siga as instruções para redefinir sua senha."
        )
      }
      .alert("Erro", isPresented: $showingError) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
    }
  }

  private var isFormValid: Bool {
    !email.isEmpty && email.contains("@")
  }

  private func sendResetEmail() {
    isLoading = true

    Task {
      do {
        try await authManager.resetPassword(email: email)
        showingSuccess = true
      } catch {
        errorMessage = error.localizedDescription
        showingError = true
      }
      isLoading = false
    }
  }
}
