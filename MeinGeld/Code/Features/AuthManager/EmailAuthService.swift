//
//  EmailAuthService.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//  Updated for dependency injection.
//

import Combine
import FirebaseAuth
import Foundation

@MainActor
final class EmailVerificationService: ObservableObject {
  @Published var isEmailVerified = false
  @Published var isCheckingVerification = false
  @Published var resendCooldown: TimeInterval = 0

  private let authManager: AuthenticationManager
  private let firebaseService: FirebaseServiceProtocol
  private var timer: Timer?

  init(
    authManager: AuthenticationManager,
    firebaseService: FirebaseServiceProtocol
  ) {
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
        isEmailVerified = firebaseUser.isEmailVerified
        isCheckingVerification = false

        if firebaseUser.isEmailVerified {
          firebaseService.logEvent(.emailVerified)
        }
      } catch {
        isCheckingVerification = false
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
    resendCooldown = 60  // 60 seconds cooldown
    timer?.invalidate()
    timer = Timer.scheduledTimer(
      timeInterval: 1.0,
      target: EmailVerificationService.self,
      selector: #selector(Self.timerTick(_:)),
      userInfo: Unmanaged.passUnretained(self).toOpaque(),
      repeats: true
    )
  }

  @objc private static func timerTick(_ timer: Timer) {
    guard let pointer = timer.userInfo as? UnsafeRawPointer else { return }
    let instance = Unmanaged<EmailVerificationService>.fromOpaque(pointer)
      .takeUnretainedValue()

    Task { @MainActor in
      if instance.resendCooldown > 0 {
        instance.resendCooldown -= 1
      } else {
        instance.timer?.invalidate()
        instance.timer = nil
      }
    }
  }
}
