//
//  MeinGeldTests.swift
//  MeinGeldTests
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Testing
import SwiftData
@testable import MeinGeld

// Mock do Firebase Service
final class MockFirebaseService: FirebaseServiceProtocol {
    var eventsLogged: [AnalyticsEvent] = []
    var errorsRecorded: [Error] = []
    
    func configure() {}
    
    func logEvent(_ event: AnalyticsEvent) {
        eventsLogged.append(event)
    }
    
    func recordError(_ error: Error, context: String) {
        errorsRecorded.append(error)
    }
    
    func recordNonFatalError(_ error: Error, context: String) {
        errorsRecorded.append(error)
    }
    
    func setUserID(_ userID: String) {}
    func setUserProperty(_ value: String?, forName name: String) {}
}

// Mock do Error Manager
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

// Testes para AuthenticationManager
@MainActor
struct AuthenticationManagerTests {
    
    @Test func testSuccessfulSignUp() async throws {
        // Arrange
        let mockFirebase = MockFirebaseService()
        let mockError = MockErrorManager()
        let container = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let authManager = AuthenticationManager(
            errorManager: mockError,
            firebaseService: mockFirebase
        )
        authManager.setModelContext(container.mainContext)
        
        // Act
        try await authManager.signUp(
            name: "Test User",
            email: "test@example.com",
            password: "TestPassword123"
        )
        
        // Assert
        #expect(authManager.isAuthenticated)
        #expect(authManager.currentUser?.email == "test@example.com")
        #expect(mockFirebase.eventsLogged.contains { $0.name == "sign_up_success" })
    }
    
    @Test func testDuplicateEmailSignUp() async throws {
        // Arrange
        let mockFirebase = MockFirebaseService()
        let mockError = MockErrorManager()
        let container = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let authManager = AuthenticationManager(
            errorManager: mockError,
            firebaseService: mockFirebase
        )
        authManager.setModelContext(container.mainContext)
        
        // Create first user
        try await authManager.signUp(
            name: "First User",
            email: "test@example.com",
            password: "TestPassword123"
        )
        
        // Act & Assert
        await #expect(throws: AppError.emailAlreadyExists) {
            try await authManager.signUp(
                name: "Second User",
                email: "test@example.com",
                password: "AnotherPassword123"
            )
        }
    }
    
    @Test func testSignOut() async throws {
        // Arrange
        let mockFirebase = MockFirebaseService()
        let mockError = MockErrorManager()
        let container = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let authManager = AuthenticationManager(
            errorManager: mockError,
            firebaseService: mockFirebase
        )
        authManager.setModelContext(container.mainContext)
        
        try await authManager.signUp(
            name: "Test User",
            email: "test@example.com",
            password: "TestPassword123"
        )
        
        // Act
        authManager.signOut()
        
        // Assert
        #expect(!authManager.isAuthenticated)
        #expect(authManager.currentUser == nil)
        #expect(mockFirebase.eventsLogged.contains { $0.name == "sign_out" })
    }
}

// Testes para Transaction
struct TransactionTests {
    
    @Test func testTransactionCreation() {
        // Arrange
        let amount: Decimal = 100.50
        let description = "Test Transaction"
        let category = TransactionCategory.food
        let type = TransactionType.expense
        
        // Act
        let transaction = Transaction(
            amount: amount,
            description: description,
            date: Date(),
            category: category,
            type: type
        )
        
        // Assert
        #expect(transaction.amount == amount)
        #expect(transaction.transactionDescription == description)
        #expect(transaction.category == category)
        #expect(transaction.type == type)
    }
}

// Testes para Validators
struct ValidatorTests {
    
    @Test func testEmailValidatorWithValidEmail() throws {
        let validator = EmailValidator()
        
        #expect(throws: Never.self) {
            try validator.validate("test@example.com")
        }
    }
    
    @Test func testEmailValidatorWithInvalidEmail() {
        let validator = EmailValidator()
        
        #expect(throws: ValidationError.self) {
            try validator.validate("invalid-email")
        }
    }
    
    @Test func testPasswordValidatorWithValidPassword() throws {
        let validator = PasswordValidator()
        
        #expect(throws: Never.self) {
            try validator.validate("ValidPassword123")
        }
    }
    
    @Test func testPasswordValidatorWithWeakPassword() {
        let validator = PasswordValidator()
        
        #expect(throws: ValidationError.self) {
            try validator.validate("weak")
        }
    }
    
    @Test func testAmountValidatorWithValidAmount() throws {
        let validator = AmountValidator()
        
        #expect(throws: Never.self) {
            try validator.validate(Decimal(100.50))
        }
    }
    
    @Test func testAmountValidatorWithNegativeAmount() {
        let validator = AmountValidator()
        
        #expect(throws: ValidationError.self) {
            try validator.validate(Decimal(-10))
        }
    }
}

// Test Helper Extensions
extension User {
    static func mock(
        email: String = "test@example.com",
        name: String = "Test User"
    ) -> User {
        User(email: email, name: name)
    }
}

extension Transaction {
    static func mock(
        amount: Decimal = 100,
        description: String = "Test Transaction",
        category: TransactionCategory = .other,
        type: TransactionType = .expense
    ) -> Transaction {
        Transaction(
            amount: amount,
            description: description,
            date: Date(),
            category: category,
            type: type
        )
    }
}
