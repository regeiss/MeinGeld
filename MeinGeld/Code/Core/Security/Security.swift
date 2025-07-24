//
//  Security.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 23/07/25.
//

import Foundation
import CryptoKit
import Security

// MARK: - Password Security Service
protocol PasswordSecurityProtocol {
    func hashPassword(_ password: String, salt: String) -> String
    func generateSalt() -> String
    func verifyPassword(_ password: String, hash: String, salt: String) -> Bool
    func validatePasswordStrength(_ password: String) -> PasswordValidationResult
}

final class PasswordSecurityService: PasswordSecurityProtocol {
    func hashPassword(_ password: String, salt: String) -> String {
        let saltedPassword = password + salt
        let inputData = Data(saltedPassword.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func generateSalt() -> String {
        let saltData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return saltData.base64EncodedString()
    }
    
    func verifyPassword(_ password: String, hash: String, salt: String) -> Bool {
        let computedHash = hashPassword(password, salt: salt)
        return computedHash == hash
    }
    
    func validatePasswordStrength(_ password: String) -> PasswordValidationResult {
        var issues: [PasswordValidationIssue] = []
        
        if password.count < 8 {
            issues.append(.tooShort)
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            issues.append(.noUppercase)
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            issues.append(.noLowercase)
        }
        
        if !password.contains(where: { $0.isNumber }) {
            issues.append(.noNumbers)
        }
        
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            issues.append(.noSpecialCharacters)
        }
        
        return PasswordValidationResult(issues: issues)
    }
}

// MARK: - Keychain Service
protocol KeychainServiceProtocol {
    func store(data: Data, for key: String) throws
    func retrieve(for key: String) throws -> Data?
    func delete(for key: String) throws
}

final class KeychainService: KeychainServiceProtocol {
    private let service = "br.com.robertogeiss.MeinGeld"
    
    func store(data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    func retrieve(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        return result as? Data
    }
    
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Enhanced Authentication Manager
@MainActor
@Observable
final class SecureAuthenticationManager {
    private let passwordSecurity: PasswordSecurityProtocol
    private let keychainService: KeychainServiceProtocol
    private let repository: UserRepositoryProtocol
    private let errorManager: ErrorManagerProtocol
    private let firebaseService: FirebaseServiceProtocol
    
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var authenticationState: AuthenticationState = .unauthenticated
    
    private let maxLoginAttempts = 5
    private let lockoutDuration: TimeInterval = 300 // 5 minutes
    
    init(
        passwordSecurity: PasswordSecurityProtocol,
        keychainService: KeychainServiceProtocol,
        repository: UserRepositoryProtocol,
        errorManager: ErrorManagerProtocol,
        firebaseService: FirebaseServiceProtocol
    ) {
        self.passwordSecurity = passwordSecurity
        self.keychainService = keychainService
        self.repository = repository
        self.errorManager = errorManager
        self.firebaseService = firebaseService
        
        Task {
            await loadStoredSession()
        }
    }
    
    private func loadStoredSession() async {
        do {
            guard let sessionData = try keychainService.retrieve(for: "user_session"),
                  let sessionInfo = try? JSONDecoder().decode(StoredSession.self, from: sessionData) else {
                authenticationState = .unauthenticated
                return
            }
            
            // Check if session is expired
            if sessionInfo.expiresAt < Date() {
                try keychainService.delete(for: "user_session")
                authenticationState = .unauthenticated
                return
            }
            
            // Load user
            currentUser = try await repository.fetchUser(by: sessionInfo.userId)
            authenticationState = .authenticated
            
        } catch {
            errorManager.handleNonFatal(error, context: "SecureAuthenticationManager.loadStoredSession")
            authenticationState = .unauthenticated
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        firebaseService.logEvent(.signInAttempt)
        
        do {
            let user = try await repository.fetchUser(by: email)
            
            // Check if account is locked
            if user.isAccountLocked() {
                firebaseService.logEvent(.signInFailure)
                throw AuthenticationError.accountLocked
            }
            
            // Verify password
            guard passwordSecurity.verifyPassword(password, hash: user.hashedPassword, salt: user.salt) else {
                // Increment login attempts
                try await repository.incrementLoginAttempts(for: user)
                
                if user.loginAttempts >= maxLoginAttempts {
                    let lockoutUntil = Date().addingTimeInterval(lockoutDuration)
                    try await repository.lockAccount(for: user, until: lockoutUntil)
                    throw AuthenticationError.accountLocked
                }
                
                firebaseService.logEvent(.signInFailure)
                throw AuthenticationError.invalidCredentials
            }
            
            // Reset login attempts on successful login
            try await repository.resetLoginAttempts(for: user)
            
            // Create session
            let session = StoredSession(
                userId: user.id,
                expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
            )
            
            let sessionData = try JSONEncoder().encode(session)
            try keychainService.store(data: sessionData, for: "user_session")
            
            currentUser = user
            authenticationState = .authenticated
            
            // Update last login
            try await repository.updateLastLogin(for: user)
            
            // Firebase setup
            firebaseService.setUserID(user.id.uuidString)
            firebaseService.logEvent(.signInSuccess)
            
        } catch {
            errorManager.handle(error, context: "SecureAuthenticationManager.signIn")
            throw error
        }
    }
    
    func signUp(name: String, email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate password strength
        let passwordValidation = passwordSecurity.validatePasswordStrength(password)
        guard passwordValidation.isValid else {
            throw AuthenticationError.weakPassword(passwordValidation.issues)
        }
        
        firebaseService.logEvent(.signUpAttempt)
        
        do {
            // Check if user already exists
            if let _ = try? await repository.fetchUser(by: email) {
                throw AuthenticationError.emailAlreadyExists
            }
            
            // Create secure password
            let salt = passwordSecurity.generateSalt()
            let hashedPassword = passwordSecurity.hashPassword(password, salt: salt)
            
            // Create user
            let user = try User(
                email: email,
                name: name,
                hashedPassword: hashedPassword,
                salt: salt
            )
            
            try await repository.createUser(user)
            
            // Auto sign in
            try await signIn(email: email, password: password)
            
            firebaseService.logEvent(.signUpSuccess)
            
        } catch {
            errorManager.handle(error, context: "SecureAuthenticationManager.signUp")
            throw error
        }
    }
    
    func signOut() async {
        do {
            try keychainService.delete(for: "user_session")
        } catch {
            errorManager.handleNonFatal(error, context: "SecureAuthenticationManager.signOut")
        }
        
        currentUser = nil
        authenticationState = .unauthenticated
        
        firebaseService.logEvent(.signOut)
    }
}

// MARK: - Supporting Types
struct StoredSession: Codable {
    let userId: UUID
    let expiresAt: Date
}

enum AuthenticationState {
    case loading
    case authenticated
    case unauthenticated
}

struct PasswordValidationResult {
    let issues: [PasswordValidationIssue]
    
    var isValid: Bool {
        issues.isEmpty
    }
}

enum PasswordValidationIssue {
    case tooShort
    case noUppercase
    case noLowercase
    case noNumbers
    case noSpecialCharacters
}

enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case accountLocked
    case emailAlreadyExists
    case weakPassword([PasswordValidationIssue])
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email ou senha inválidos"
        case .accountLocked:
            return "Conta temporariamente bloqueada devido a muitas tentativas de login"
        case .emailAlreadyExists:
            return "Este email já está em uso"
        case .weakPassword(let issues):
            return "Senha muito fraca: \(issues.map { $0.description }.joined(separator: ", "))"
        }
    }
}

enum KeychainError: Error {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
}
