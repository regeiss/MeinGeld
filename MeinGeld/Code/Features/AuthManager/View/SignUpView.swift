//
//  SignUpView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import SwiftUI

struct SignUpView: View {
  @State private var name = ""
  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""
  @State private var showingAlert = false
  @State private var alertMessage = ""
  @State private var isPasswordVisible = false
  @State private var isConfirmPasswordVisible = false
  @State private var agreedToTerms = false

  private let authManager = AuthenticationManager.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Name Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Nome completo")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Digite seu nome", text: $name)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .textContentType(.name)
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

        // Password Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Senha")
            .font(.subheadline)
            .fontWeight(.medium)

          HStack {
            if isPasswordVisible {
              TextField("Mínimo 6 caracteres", text: $password)
                .textContentType(.newPassword)
            } else {
              SecureField("Mínimo 6 caracteres", text: $password)
                .textContentType(.newPassword)
            }

            Button(action: { isPasswordVisible.toggle() }) {
              Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
            }
          }
          .textFieldStyle(RoundedBorderTextFieldStyle())

          // Password strength indicator
          PasswordStrengthIndicator(password: password)
        }

        // Confirm Password Field
        VStack(alignment: .leading, spacing: 8) {
          Text("Confirmar senha")
            .font(.subheadline)
            .fontWeight(.medium)

          HStack {
            if isConfirmPasswordVisible {
              TextField("Confirme sua senha", text: $confirmPassword)
                .textContentType(.newPassword)
            } else {
              SecureField("Confirme sua senha", text: $confirmPassword)
                .textContentType(.newPassword)
            }

            Button(action: { isConfirmPasswordVisible.toggle() }) {
              Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
            }
          }
          .textFieldStyle(RoundedBorderTextFieldStyle())

          if !confirmPassword.isEmpty && password != confirmPassword {
            Text("Senhas não coincidem")
              .font(.caption)
              .foregroundColor(.red)
          }
        }

        // Terms and Conditions
        HStack {
          Button(action: { agreedToTerms.toggle() }) {
            Image(
              systemName: agreedToTerms ? "checkmark.square.fill" : "square"
            )
            .foregroundColor(agreedToTerms ? .blue : .gray)
          }

          Text(
            "Concordo com os **[Termos de Uso](termos)** e **[Política de Privacidade](privacidade)**"
          )
          .font(.caption)
          .tint(.blue)

          Spacer()
        }

        // Sign Up Button
        Button(action: signUp) {
          HStack {
            if authManager.isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            } else {
              Text("Criar Conta")
                .fontWeight(.semibold)
            }
          }
          .frame(maxWidth: .infinity, minHeight: 50)
          .background(isFormValid ? Color.green : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(10)
        }
        .disabled(!isFormValid || authManager.isLoading)

        // Success Message
        Text("Após criar sua conta, você receberá um email de verificação.")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        // Error Message
        if let errorMessage = authManager.errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
      }
      .padding()
    }
    .alert("Erro", isPresented: $showingAlert) {
      Button("OK") {}
    } message: {
      Text(alertMessage)
    }
  }

  private var isFormValid: Bool {
    !name.isEmpty && !email.isEmpty && email.contains("@") && !password.isEmpty
      && password == confirmPassword && password.count >= 6 && agreedToTerms
  }

  private func signUp() {
    Task {
      do {
        try await authManager.signUp(
          name: name,
          email: email,
          password: password
        )
      } catch {
        // O erro já é tratado no AuthManager
        print("Sign up error handled by AuthManager")
      }
    }
  }
}
