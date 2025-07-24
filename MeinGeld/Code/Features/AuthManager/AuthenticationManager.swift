import Combine
import FirebaseAuth
import Foundation
import OSLog
import SwiftData

// MARK: - Auth Protocols
protocol AuthenticationManagerProtocol: AnyObject {
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

// MARK: - Firebase Authentication Manager
@Observable
final class AuthenticationManager: AuthenticationManagerProtocol, @unchecked
  Sendable
{
  static let shared = AuthenticationManager()

  // MARK: - Properties
  private(set) var currentUser: User?
  var isAuthenticated: Bool { currentUser != nil }
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  // MARK: - Private Properties
  private var modelContext: ModelContext?
  private let errorManager: ErrorManagerProtocol
  private let firebaseService: FirebaseServiceProtocol
  private let logger = Logger(
    subsystem: "com.meingeld.app",
    category: "AuthenticationManager"
  )
  private var authStateHandle: AuthStateDidChangeListenerHandle?

  // MARK: - Initialization
  private init() {
    self.errorManager = ErrorManager.shared
    self.firebaseService = FirebaseService.shared
  }

  deinit {
    if let handle = authStateHandle {
      Auth.auth().removeStateDidChangeListener(handle)
    }
  }

  // MARK: - Public Methods
  @MainActor
  func setModelContext(_ context: ModelContext) {
    self.modelContext = context

    // Configura o listener apenas quando o contexto for definido
    setupAuthStateListener()

    // Se já tem usuário autenticado no Firebase, carrega dados locais
    if let firebaseUser = Auth.auth().currentUser {
      Task {
        await loadOrCreateUser(from: firebaseUser)
      }
    }
  }

  @MainActor
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
      let authResult = try await Auth.auth().signIn(
        withEmail: email,
        password: password
      )

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
      errorMessage = appError.errorDescription
      throw appError
    }

    isLoading = false
  }

  @MainActor
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
      let authResult = try await Auth.auth().createUser(
        withEmail: email,
        password: password
      )

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
      errorMessage = appError.errorDescription
      throw appError
    }

    isLoading = false
  }

  @MainActor
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

  @MainActor
  func resetPassword(email: String) async throws {
    guard !email.isEmpty else {
      throw AppError.emailBadlyFormatted
    }

    isLoading = true
    errorMessage = nil

    do {
      try await Auth.auth().sendPasswordReset(withEmail: email)

      // Analytics - reset de senha
      firebaseService.logEvent(
        AnalyticsEvent(
          name: "password_reset_sent",
          parameters: ["email": email]
        )
      )

      logger.info("Email de reset de senha enviado para: \(email)")

    } catch let error as NSError {
      let appError = handleAuthError(error)
      errorManager.handle(
        appError,
        context: "AuthenticationManager.resetPassword"
      )
      errorMessage = appError.errorDescription
      throw appError
    }

    isLoading = false
  }

  @MainActor
  func updateProfile(name: String, profileImageData: Data?) async throws {
    guard let firebaseUser = Auth.auth().currentUser,
      let localUser = currentUser,
      let context = modelContext
    else {
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

  @MainActor
  func deleteAccount() async throws {
    guard let firebaseUser = Auth.auth().currentUser,
      let localUser = currentUser,
      let context = modelContext
    else {
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
      errorManager.handle(
        appError,
        context: "AuthenticationManager.deleteAccount"
      )
      errorMessage = appError.errorDescription
      throw appError
    }

    isLoading = false
  }

  // MARK: - Private Methods
  private func setupAuthStateListener() {
    // Remove listener anterior se existir
    if let handle = authStateHandle {
      Auth.auth().removeStateDidChangeListener(handle)
    }

    authStateHandle = Auth.auth().addStateDidChangeListener {
      [weak self] _, user in
      Task { @MainActor in
        guard let self = self else { return }

        if let user = user {
          await self.loadOrCreateUser(from: user)
        } else {
          self.currentUser = nil
        }
      }
    }
  }

  @MainActor
  private func loadOrCreateUser(from firebaseUser: FirebaseAuth.User) async {
    guard let context = modelContext else { return }

    do {
      guard let userEmail = firebaseUser.email else {
        logger.error("Firebase user has no email; cannot fetch local user.")
        return
      }

      let descriptor = FetchDescriptor<User>(
        predicate: #Predicate<User> { $0.email == userEmail }
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
      errorManager.handle(
        error,
        context: "AuthenticationManager.loadOrCreateUser"
      )
    }
  }

  @MainActor
  private func createLocalUser(
    from firebaseUser: FirebaseAuth.User,
    name: String
  ) async {
    guard let context = modelContext,
      let email = firebaseUser.email
    else { return }

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
      errorManager.handle(
        error,
        context: "AuthenticationManager.createLocalUser"
      )
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
