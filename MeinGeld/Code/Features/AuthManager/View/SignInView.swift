//
//  SignInView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var showingForgotPassword = false
    @State private var alertMessage = ""
    @State private var isPasswordVisible = false
    
    private let authManager = AuthenticationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
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
                        TextField("Digite sua senha", text: $password)
                            .textContentType(.password)
                    } else {
                        SecureField("Digite sua senha", text: $password)
                            .textContentType(.password)
                    }
                    
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Forgot Password Link
            HStack {
                Spacer()
                Button("Esqueceu a senha?") {
                    showingForgotPassword = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Sign In Button
            Button(action: signIn) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Entrar")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isFormValid || authManager.isLoading)
            
            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .alert("Erro", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() {
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                // O erro já é tratado no AuthManager
                print("Sign in error handled by AuthManager")
            }
        }
    }
}
