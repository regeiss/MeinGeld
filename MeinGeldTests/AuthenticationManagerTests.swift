import Testing
import Foundation
@testable import MeinGeld

// MARK: - Mock Dependencies
final class MockFirebaseService: FirebaseServiceProtocol {
    var loggedEvents: [AnalyticsEvent] = []
    var recordedErrors: [(Error, String)] = []
    
    func configure() {
        // Mock implementation
    }
    
    func logEvent(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }
    
    func recordError(_ error: Error, context: String) {
        recordedErrors.append((error, context))
    }
    
    func recordNonFatalError(_ error: Error, context: String) {
        recordedErrors.append((error, context))
    }
    
    func setUserID(_ userID: String) {
        // Mock implementation
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        // Mock implementation
    }
}

final class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: Data] = [:]
    
    func store(data: Data, for key: String) throws {
        storage[key] = data
    }
    
    func retrieve(for key: String) throws -> Data? {
        return storage[key]
    }
    
    func delete(for key: String) throws {
        storage.removeValue(forKey: key)
    }
}

final class MockPasswordSecurity: PasswordSecurityProtocol {
    func hashPassword(_ password: String, salt: String) -> String {
        return "\(password)_hashed_with_\(salt)"
    }
    
    func generateSalt() -> String {
        return "mock_salt_\(UUID().uuidString)"
    }
    
    func verifyPassword(_ password: String, hash: String, salt: String) -> Bool {
        return hashPassword(password, salt: salt) == hash
    }
    
    func validatePasswordStrength(_ password: String) -> PasswordValidationResult {
        var issues: [PasswordValidationIssue] = []
        
        if password.count < 8 {
            issues.append(.tooShort)
        }
        
        return PasswordValidationResult(issues: issues)
    }
}

// MARK: - Model Tests
struct UserModelTests {
    
    @Test("User creation with valid data should succeed")
    func userCreationValid() async throws {
        let user = try User(
            email: "test@example.com",
            name: "Test User",
            hashedPassword: "hashed_password",
            salt: "salt123"
        )
        
        #expect(user.email == "test@example.com")
        #expect(user.name == "Test User")
        #expect(!user.isEmailVerified)
        #expect(user.loginAttempts == 0)
    }
    
    @Test("User creation with invalid email should fail")
    func userCreationInvalidEmail() async throws {
        #expect(throws: ValidationError.invalidEmail) {
            try User(
                email: "invalid-email",
                name: "Test User",
                hashedPassword: "hashed_password",
                salt: "salt123"
            )
        }
    }
    
    @Test("User account locking mechanism")
    func userAccountLocking() async throws {
        let user = try User(
            email: "test@example.com",
            name: "Test User",
            hashedPassword: "hashed_password",
            salt: "salt123"
        )
        
        #expect(!user.isAccountLocked())
        
        user.lockedUntil = Date().addingTimeInterval(300) // 5 minutes
        #expect(user.isAccountLocked())
        
        user.lockedUntil = Date().addingTimeInterval(-300) // 5 minutes ago
        #expect(!user.isAccountLocked())
    }
}

struct TransactionModelTests {
    
    @Test("Transaction creation with valid data should succeed")
    func transactionCreationValid() async throws {
        let transaction = try Transaction(
            amount: -100.50,
            description: "Test Expense",
            date: Date(),
            category: .food,
            type: .expense
        )
        
        #expect(transaction.amount == -100.50)
        #expect(transaction.transactionDescription == "Test Expense")
        #expect(transaction.category == .food)
        #expect(transaction.type == .expense)
    }
    
    @Test("Transaction with zero amount should fail")
    func transactionZeroAmount() async throws {
        #expect(throws: ValidationError.invalidAmount("Amount cannot be zero")) {
            try Transaction(
                amount: 0,
                description: "Test Transaction",
                date: Date(),
                category: .other,
                type: .expense
            )
        }
    }
    
    @Test("Expense transaction with positive amount should fail")
    func expensePositiveAmount() async throws {
        #expect(throws: ValidationError.invalidAmount("Expense must be negative")) {
            try Transaction(
                amount: 100,
                description: "Test Expense",
                date: Date(),
                category: .food,
                type: .expense
            )
        }
    }
    
    @Test("Income transaction with negative amount should fail")
    func incomeNegativeAmount() async throws {
        #expect(throws: ValidationError.invalidAmount("Income must be positive")) {
            try Transaction(
                amount: -100,
                description: "Test Income",
                date: Date(),
                category: .salary,
                type: .income
            )
        }
    }
}

// MARK: - Service Tests
struct PasswordSecurityServiceTests {
    
    @Test("Password hashing should be consistent")
    func passwordHashingConsistency() async throws {
        let service = PasswordSecurityService()
        let password = "testPassword123!"
        let salt = service.generateSalt()
        
        let hash1 = service.hashPassword(password, salt: salt)
        let hash2 = service.hashPassword(password, salt: salt)
        
        #expect(hash1 == hash2)
    }
    
    @Test("Password verification should work correctly")
    func passwordVerification() async throws {
        let service = PasswordSecurityService()
        let password = "testPassword123!"
        let salt = service.generateSalt()
        let hash = service.hashPassword(password, salt: salt)
        
        #expect(service.verifyPassword(password, hash: hash, salt: salt))
        #expect(!service.verifyPassword("wrongPassword", hash: hash, salt: salt))
    }
    
    @Test("Password strength validation")
    func passwordStrengthValidation() async throws {
        let service = PasswordSecurityService()
        
        // Weak password
        let weakResult = service.validatePasswordStrength("123")
        #expect(!weakResult.isValid)
        #expect(weakResult.issues.contains(.tooShort))
        #expect(weakResult.issues.contains(.noUppercase))
        #expect(weakResult.issues.contains(.noLowercase))
        
        // Strong password
        let strongResult = service.validatePasswordStrength("StrongPass123!")
        #expect(strongResult.isValid)
    }
}

struct AuthenticationManagerTests {
    
    @Test("Successful sign in should authenticate user")
    func successfulSignIn() async throws {
        let mockFirebase = MockFirebaseService()
        let mockKeychain = MockKeychainService()
        let mockPasswordSecurity = MockPasswordSecurity()
        let mockRepository = MockUserRepository()
        let mockErrorManager = MockErrorManager()
        
        let authManager = SecureAuthenticationManager(
            passwordSecurity: mockPasswordSecurity,
            keychainService: mockKeychain,
            repository: mockRepository,
            errorManager: mockErrorManager,
            firebaseService: mockFirebase
        )
        
        // Setup test user
        let salt = mockPasswordSecurity.generateSalt()
        let hash = mockPasswordSecurity.hashPassword("testPassword", salt: salt)
        let user = try User(
            email: "test@example.com",
            name: "Test User",
            hashedPassword: hash,
            salt: salt
        )
        mockRepository.users["test@example.com"] = user
        
        // Test sign in
        try await authManager.signIn(email: "test@example.com", password: "testPassword")
        
        #expect(authManager.isAuthenticated)
        #expect(authManager.currentUser?.email == "test@example.com")
        #expect(mockFirebase.loggedEvents.contains { $0.name == "sign_in_success" })
    }
    
    @Test("Failed sign in should not authenticate user")
    func failedSignIn() async throws {
        let mockFirebase = MockFirebaseService()
        let mockKeychain = MockKeychainService()
        let mockPasswordSecurity = MockPasswordSecurity()
        let mockRepository = MockUserRepository()
        let mockErrorManager = MockErrorManager()
        
        let authManager = SecureAuthenticationManager(
            passwordSecurity: mockPasswordSecurity,
            keychainService: mockKeychain,
            repository: mockRepository,
            errorManager: mockErrorManager,
            firebaseService: mockFirebase
        )
        
        #expect(throws: AuthenticationError.invalidCredentials) {
            try await authManager.signIn(email: "nonexistent@example.com", password: "wrongPassword")
        }
        
        #expect(!authManager.isAuthenticated)
        #expect(mockFirebase.loggedEvents.contains { $0.name == "sign_in_failure" })
    }
}

// MARK: - Mock Repository
final class MockUserRepository: UserRepositoryProtocol {
    var users: [String: User] = [:]
    
    func fetchUser(by email: String) async throws -> User {
        guard let user = users[email] else {
            throw AuthenticationError.invalidCredentials
        }
        return user
    }
    
    func fetchUser(by id: UUID) async throws -> User {
        guard let user = users.values.first(where: { $0.id == id }) else {
            throw AuthenticationError.invalidCredentials
        }
        return user
    }
    
    func createUser(_ user: User) async throws {
        users[user.email] = user
    }
    
    func incrementLoginAttempts(for user: User) async throws {
        user.loginAttempts += 1
    }
    
    func resetLoginAttempts(for user: User) async throws {
        user.loginAttempts = 0
    }
    
    func lockAccount(for user: User, until date: Date) async throws {
        user.lockedUntil = date
    }
    
    func updateLastLogin(for user: User) async throws {
        user.lastLoginAt = Date()
    }
}

final class MockErrorManager: ErrorManagerProtocol {
    var handledErrors: [(Error, String)] = []
    var warnings: [(String, String)] = []
    var infos: [(String, String)] = []
    
    func handle(_ error: Error, context: String) {
        handledErrors.append((error, context))
    }
    
    func handleNonFatal(_ error: Error, context: String) {
        handledErrors.append((error, context))
    }
    
    func logWarning(_ message: String, context: String) {
        warnings.append((message, context))
    }
    
    func logInfo(_ message: String, context: String) {
        infos.append((message, context))
    }
}

// MARK: - User Repository Protocol
protocol UserRepositoryProtocol {
    func fetchUser(by email: String) async throws -> User
    func fetchUser(by id: UUID) async throws -> User
    func createUser(_ user: User) async throws
    func incrementLoginAttempts(for user: User) async throws
    func resetLoginAttempts(for user: User) async throws
    func lockAccount(for user: User, until date: Date) async throws
    func updateLastLogin(for user: User) async throws
}
