//
//  AnalyticsView+Extension.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation

extension AnalyticsEvent {
    static let emailVerificationSent = AnalyticsEvent(name: "email_verification_sent")
    static let emailVerified = AnalyticsEvent(name: "email_verified")
    static let biometricEnabled = AnalyticsEvent(name: "biometric_enabled")
    static let biometricDisabled = AnalyticsEvent(name: "biometric_disabled")
    static let passwordChanged = AnalyticsEvent(name: "password_changed")
    static let securitySettingsViewed = AnalyticsEvent(name: "security_settings_viewed")
}
