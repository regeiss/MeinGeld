//
//  BiometricAuthService.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import LocalAuthentication
import SwiftUI
import FirebaseAuth

// MARK: - Biometric Authentication Service
@MainActor
final class BiometricAuthService: ObservableObject {
    @Published var biometricType: LABiometryType = .none
    @Published var isAvailable = false
    @Published var error: BiometricError?
    
    private let context = LAContext()
    private let keychain = KeychainService()
    
    enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case lockout
        case userCancel
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Autenticação biométrica não disponível"
            case .notEnrolled:
                return "Nenhuma biometria cadastrada no dispositivo"
            case .lockout:
                return "Muitas tentativas falharam. Tente novamente mais tarde"
            case .userCancel:
                return "Autenticação cancelada pelo usuário"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }
    
    init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isAvailable = false
            biometricType = .none
            return
        }
        
        isAvailable = true
        biometricType = context.biometryType
    }
    
    func authenticateWithBiometrics() async -> Bool {
        guard isAvailable else {
            error = .notAvailable
            return false
        }
        
        do {
            let reason = "Use \(biometricTypeName) para acessar suas finanças"
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return result
        } catch let authError as LAError {
            error = mapLAError(authError)
            return false
        } catch {
            self.error = .unknown(error)
            return false
        }
    }
    
    private var biometricTypeName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "biometria"
        }
    }
    
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel, .userFallback:
            return .userCancel
        default:
            return .unknown(error)
        }
    }
}
