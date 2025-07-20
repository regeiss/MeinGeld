//
//  EmailAuthService.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class EmailVerificationService: ObservableObject {
    @Published var isEmailVerified = false
    @Published var isCheckingVerification = false
    @Published var resendCooldown: TimeInterval = 0
    
    private let authManager: AuthenticationManager
    private let firebaseService: FirebaseServiceProtocol
    private var timer: Timer?
    
    init(authManager: AuthenticationManager = .shared, firebaseService: FirebaseServiceProtocol = FirebaseService.shared) {
        self.authManager = authManager
        self.firebaseService = firebaseService
        checkEmailVerification()
    }
    
    func checkEmailVerification() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        isCheckingVerification = true
        
        Task {
            do {
                try await firebaseUser.reload()
                await MainActor.run {
                    isEmailVerified = firebaseUser.isEmailVerified
                    isCheckingVerification = false
                }
                
                if firebaseUser.isEmailVerified {
                    firebaseService.logEvent(.emailVerified)
                }
            } catch {
                await MainActor.run {
                    isCheckingVerification = false
                }
            }
        }
    }
    
    func resendVerificationEmail() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AppError.userNotFound
        }
        
        guard resendCooldown <= 0 else {
            throw AppError.tooManyRequests
        }
        
        try await firebaseUser.sendEmailVerification()
        
        await MainActor.run {
            startResendCooldown()
        }
        
        firebaseService.logEvent(.emailVerificationSent)
    }
    
    private func startResendCooldown() {
        resendCooldown = 60 // 60 seconds cooldown
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.resendCooldown > 0 {
                    self.resendCooldown -= 1
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }
}

