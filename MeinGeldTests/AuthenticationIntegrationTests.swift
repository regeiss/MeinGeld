//
//  AuthenticationIntegrationTests.swift
//  MeinGeldTests
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import XCTest
import FirebaseAuth
@testable import MeinGeld

class AuthenticationIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Configurar ambiente de teste
        if Auth.auth().currentUser != nil {
            try? Auth.auth().signOut()
        }
    }
    
    @MainActor
    func testSignUpFlow() async throws {
        let authManager = AuthenticationManager.shared
        let testEmail = "test\(Date().timeIntervalSince1970)@example.com"
        
        try await authManager.signUp(
            name: "Test User",
            email: testEmail,
            password: "TestPassword123"
        )
        
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.currentUser?.email, testEmail)
    }
    
    @MainActor
    func testSignInFlow() async throws {
        // Primeiro criar usuário
        let authManager = AuthenticationManager.shared
        let testEmail = "test\(Date().timeIntervalSince1970)@example.com"
        
        try await authManager.signUp(
            name: "Test User",
            email: testEmail,
            password: "TestPassword123"
        )
        
        // Fazer logout
        authManager.signOut()
        XCTAssertFalse(authManager.isAuthenticated)
        
        // Fazer login novamente
        try await authManager.signIn(email: testEmail, password: "TestPassword123")
        XCTAssertTrue(authManager.isAuthenticated)
    }
}
