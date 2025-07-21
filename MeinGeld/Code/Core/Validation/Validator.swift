//
//  Validator.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftUI

// Sistema de validação
protocol Validator {
    associatedtype Value
    func validate(_ value: Value) throws
}

struct ValidationError: LocalizedError {
    let message: String
    var validationErrorDescription: String? { message }
}

// Validadores específicos
struct EmailValidator: Validator {
    func validate(_ email: String) throws {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard predicate.evaluate(with: email) else {
            throw ValidationError(message: "Email inválido")
        }
    }
}

struct PasswordValidator: Validator {
    func validate(_ password: String) throws {
        guard password.count >= 8 else {
            throw ValidationError(message: "Senha deve ter pelo menos 8 caracteres")
        }
        
        guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
            throw ValidationError(message: "Senha deve conter pelo menos uma letra maiúscula")
        }
        
        guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else {
            throw ValidationError(message: "Senha deve conter pelo menos uma letra minúscula")
        }
        
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
            throw ValidationError(message: "Senha deve conter pelo menos um número")
        }
    }
}

struct AmountValidator: Validator {
    func validate(_ amount: Decimal) throws {
        guard amount > 0 else {
            throw ValidationError(message: "Valor deve ser maior que zero")
        }
        
        guard amount <= 999999.99 else {
            throw ValidationError(message: "Valor muito alto")
        }
    }
}

// Uso nos formulários
//struct SignUpView: View {
//    @State private var email = ""
//    @State private var password = ""
//    @State private var validationErrors: [ValidationError] = []
//    
//    private let emailValidator = EmailValidator()
//    private let passwordValidator = PasswordValidator()
//    
//    var body: some View {
//        VStack {
//            TextField("Email", text: $email)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .onChange(of: email) { _, newValue in
//                    validateEmail(newValue)
//                }
//            
//            SecureField("Senha", text: $password)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .onChange(of: password) { _, newValue in
//                    validatePassword(newValue)
//                }
//            
//            // Mostrar erros de validação
//            ForEach(validationErrors, id: \.message) { error in
//                Text(error.message)
//                    .foregroundColor(.red)
//                    .font(.caption)
//            }
//            
//            Button("Cadastrar") {
//                signUp()
//            }
//            .disabled(!isFormValid)
//        }
//    }
//    
//    private func validateEmail(_ email: String) {
//        do {
//            try emailValidator.validate(email)
//            removeValidationError(containing: "Email")
//        } catch let error as ValidationError {
//            addValidationError(error)
//        } catch {}
//    }
//    
//    private func validatePassword(_ password: String) {
//        do {
//            try passwordValidator.validate(password)
//            removeValidationError(containing: "Senha")
//        } catch let error as ValidationError {
//            addValidationError(error)
//        } catch {}
//    }
//    
//    private var isFormValid: Bool {
//        validationErrors.isEmpty && !email.isEmpty && !password.isEmpty
//    }
//    
//    private func addValidationError(_ error: ValidationError) {
//        if !validationErrors.contains(where: { $0.message == error.message }) {
//            validationErrors.append(error)
//        }
//    }
//    
//    private func removeValidationError(containing text: String) {
//        validationErrors.removeAll { $0.message.contains(text) }
//    }
//}

// Extension para Decimal com validação
extension Decimal {
    static func validated(from string: String) throws -> Decimal {
        guard let decimal = Decimal(string: string) else {
            throw ValidationError(message: "Formato de número inválido")
        }
        
        try AmountValidator().validate(decimal)
        return decimal
    }
}
