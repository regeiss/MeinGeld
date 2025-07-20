//
//  ChangePasswordView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Senha Atual") {
                    SecureField("Digite sua senha atual", text: $currentPassword)
                        .textContentType(.password)
                }
                
                Section("Nova Senha") {
                    SecureField("Digite a nova senha", text: $newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirme a nova senha", text: $confirmPassword)
                        .textContentType(.newPassword)
                    
                    PasswordStrengthIndicator(password: newPassword)
                }
                
                Section {
                    Button(action: changePassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Alterar Senha")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Alterar Senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Resultado", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("sucesso") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6 &&
        newPassword != currentPassword
    }
    
    private func changePassword() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                // Re-authenticate with current password
                let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
                try await user.reauthenticate(with: credential)
                
                // Update password
                try await user.updatePassword(to: newPassword)
                
                await MainActor.run {
                    alertMessage = "Senha alterada com sucesso!"
                    showingAlert = true
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
}

