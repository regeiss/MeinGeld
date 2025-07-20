//
//  AuthManager.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//
import Foundation
import SwiftData
import FirebaseAuth
import OSLog

// MARK: - Auth Protocols
protocol AuthenticationManagerProtocol: ObservableObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func setModelContext(_ context: ModelContext)
    func signIn(email: String, password: String) async throws
    func signUp(name: String, email: String, password: String) async throws
    func signOut()
    func resetPassword(email: String) async throws
    func updateProfile(name: String, profileImageData: Data?) async throws
    func deleteAccount() async throws
}

// MARK: - Enhanced App Errors
extension AppError {
    // Firebase Auth specific errors
    case emailNotVerified
    case userDisabled
    case tooManyRequests
    case operationNotAllowed
    case weakPassword
    case emailBadlyFormatted
    case userTokenExpired
    case networkUnavailable
    case internalError
    
    static func from(authError: AuthErrorCode) -> AppError {
        switch authError {
        case .emailAlreadyInUse:
            return .emailAlreadyExists
        case .userNotFound:
            return .userNotFound
        case .wrongPassword, .invalidCredential:
            return .invalidCredentials
        case .emailNotVerified:
            return .emailNotVerified
        case .userDisabled:
            return .userDisabled
        case .tooManyRequests:
            return .tooManyRequests
        case .operationNotAllowed:
            return .operationNotAllowed
        case .weakPassword:
            return .weakPassword
        case .invalidEmail:
            return .emailBadlyFormatted
        case .userTokenExpired:
            return .userTokenExpired
        case .networkError:
            return .networkUnavailable
        case .internalError:
            return .internalError
        default:
            return .authenticationFailed
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .emailNotVerified:
            return "Por favor, verifique seu email antes de fazer login"
        case .userDisabled:
            return "Sua conta foi desabilitada. Entre em contato com o suporte"
        case .tooManyRequests:
            return "Muitas tentativas de login. Tente novamente mais tarde"
        case .operationNotAllowed:
            return "Operação não permitida. Verifique as configurações"
        case .weakPassword:
            return "Senha muito fraca. Use pelo menos 6 caracteres"
        case .emailBadlyFormatted:
            return "Formato de email inválido"
        case .userTokenExpired:
            return "Sessão expirada. Faça login novamente"
        case .networkUnavailable:
            return "Sem conexão com a internet"
        case .internalError:
            return "Erro interno. Tente novamente"
        default:
            return super.errorDescription
        }
    }
}

// MARK: - Firebase Authentication Manager
@MainActor
@Observable
final class AuthenticationManager: AuthenticationManagerProtocol {
    static let shared = AuthenticationManager()
    
    // MARK: - Published Properties
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private let errorManager: ErrorManagerProtocol
    private let firebaseService: FirebaseServiceProtocol
    private let logger = Logger(subsystem: "com.meingeld.app", category: "AuthenticationManager")
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    private init() {
        self.errorManager = ErrorManager.shared
        self.firebaseService = FirebaseService.shared
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Public Methods
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Se já tem usuário autenticado no Firebase, carrega dados locais
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                await loadOrCreateUser(from: firebaseUser)
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AppError.invalidCredentials
        }
        
        isLoading = true
        errorMessage = nil
        
        // Analytics - tentativa de login
        firebaseService.logEvent(.signInAttempt)
        
        do {
            // Autenticação com Firebase
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Carrega ou cria usuário local
            await loadOrCreateUser(from: authResult.user)
            
            // Configura Analytics
            setupFirebaseUserProperties()
            
            // Analytics - login bem-sucedido
            firebaseService.logEvent(.signInSuccess)
            
            logger.info("Login realizado com sucesso: \(email)")
            
        } catch let error as NSError {
            let appError = handleAuthError(error)
            firebaseService.logEvent(.signInFailure)
            errorManager.handle(appError, context: "AuthenticationManager.signIn")
            errorMessage = appError.localizedDescription
            throw appError
        }
        
        isLoading = false
    }
    
    func signUp(name: String, email: String, password: String) async throws {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AppError.invalidCredentials
        }
        
        isLoading = true
        errorMessage = nil
        
        // Analytics - tentativa de cadastro
        firebaseService.logEvent(.signUpAttempt)
        
        do {
            // Criação de conta no Firebase
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Atualiza display name no Firebase
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Envia email de verificação
            try await authResult.user.sendEmailVerification()
            
            // Cria usuário local
            await createLocalUser(from: authResult.user, name: name)
            
            // Configura Analytics
            setupFirebaseUserProperties()
            
            // Analytics - cadastro bem-sucedido
            firebaseService.logEvent(.signUpSuccess)
            
            logger.info("Usuário criado com sucesso: \(email)")
            
        } catch let error as NSError {
            let appError = handleAuthError(error)
            firebaseService.logEvent(.signUpFailure)
            errorManager.handle(appError, context: "AuthenticationManager.signUp")
            errorMessage = appError.localizedDescription
            throw appError
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            
            // Limpa dados locais
            currentUser = nil
            
            // Remove dados do usuário do Firebase Analytics
            firebaseService.setUserID("")
            
            // Analytics - logout
            firebaseService.logEvent(.signOut)
            
            logger.info("Logout realizado com sucesso")
            
        } catch {
            errorManager.handle(error, context: "AuthenticationManager.signOut")
        }
    }
    
    func resetPassword(email: String) async throws {
        guard !email.isEmpty else {
            throw AppError.emailBadlyFormatted
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            
            // Analytics - reset de senha
            firebaseService.logEvent(AnalyticsEvent(name: "password_reset_sent", parameters: ["email": email]))
            
            logger.info("Email de reset de senha enviado para: \(email)")
            
        } catch let error as NSError {
            let appError = handleAuthError(error)
            errorManager.handle(appError, context: "AuthenticationManager.resetPassword")
            errorMessage = appError.localizedDescription
            throw appError
        }
        
        isLoading = false
    }
    
    func updateProfile(name: String, profileImageData: Data?) async throws {
        guard let firebaseUser = Auth.auth().currentUser,
              let localUser = currentUser,
              let context = modelContext else {
            throw AppError.userNotFound
        }
        
        isLoading = true
        
        do {
            // Atualiza no Firebase
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Atualiza localmente
            localUser.name = name
            if let imageData = profileImageData {
                localUser.profileImageData = imageData
                firebaseService.logEvent(.profilePhotoUpdated)
            }
            
            try context.save()
            
            // Atualiza propriedades do Firebase
            firebaseService.setUserProperty(name, forName: "user_name")
            firebaseService.logEvent(.profileEdited)
            
            logger.info("Perfil atualizado com sucesso")
            
        } catch {
            errorManager.handle(error, context: "AuthenticationManager.updateProfile")
            throw error
        }
        
        isLoading = false
    }
    
    func deleteAccount() async throws {
        guard let firebaseUser = Auth.auth().currentUser,
              let localUser = currentUser,
              let context = modelContext else {
            throw AppError.userNotFound
        }
        
        isLoading = true
        
        do {
            // Remove dados locais primeiro
            context.delete(localUser)
            try context.save()
            
            // Remove conta do Firebase
            try await firebaseUser.delete()
            
            // Limpa estado local
            currentUser = nil
            
            // Analytics - conta deletada
            firebaseService.logEvent(AnalyticsEvent(name: "account_deleted"))
            
            logger.info("Conta deletada com sucesso")
            
        } catch let error as NSError {
            let appError = handleAuthError(error)
            errorManager.handle(appError, context: "AuthenticationManager.deleteAccount")
            errorMessage = appError.localizedDescription
            throw appError
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadOrCreateUser(from: user)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func loadOrCreateUser(from firebaseUser: FirebaseAuth.User) async {
        guard let context = modelContext else { return }
        
        do {
            // Tenta carregar usuário existente
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate<User> { $0.email == firebaseUser.email ?? "" }
            )
            let users = try context.fetch(descriptor)
            
            if let existingUser = users.first {
                currentUser = existingUser
                logger.info("Usuário local carregado: \(existingUser.email)")
            } else {
                // Cria novo usuário local
                await createLocalUser(
                    from: firebaseUser,
                    name: firebaseUser.displayName ?? "Usuário"
                )
                logger.info("Novo usuário local criado: \(firebaseUser.email ?? "")")
            }
            
        } catch {
            errorManager.handle(error, context: "AuthenticationManager.loadOrCreateUser")
        }
    }
    
    private func createLocalUser(from firebaseUser: FirebaseAuth.User, name: String) async {
        guard let context = modelContext,
              let email = firebaseUser.email else { return }
        
        let newUser = User(
            email: email,
            name: name,
            createdAt: Date(),
            preferredCurrency: "BRL"
        )
        
        context.insert(newUser)
        
        do {
            try context.save()
            currentUser = newUser
        } catch {
            errorManager.handle(error, context: "AuthenticationManager.createLocalUser")
        }
    }
    
    private func setupFirebaseUserProperties() {
        guard let user = currentUser else { return }
        
        firebaseService.setUserID(user.id.uuidString)
        firebaseService.setUserProperty(user.email, forName: "user_email")
        firebaseService.setUserProperty(user.name, forName: "user_name")
        firebaseService.setUserProperty("ios", forName: "platform")
    }
    
    private func handleAuthError(_ error: NSError) -> AppError {
        if let authErrorCode = AuthErrorCode(rawValue: error.code) {
            return AppError.from(authError: authErrorCode)
        }
        return AppError.unknown(underlying: error)
    }
}

// MARK: - Enhanced Analytics Events
extension AnalyticsEvent {
    static let passwordResetRequested = AnalyticsEvent(name: "password_reset_requested")
    static let passwordResetCompleted = AnalyticsEvent(name: "password_reset_completed")
    static let accountDeleted = AnalyticsEvent(name: "account_deleted")
    static let emailVerificationSent = AnalyticsEvent(name: "email_verification_sent")
    static let emailVerified = AnalyticsEvent(name: "email_verified")
}
