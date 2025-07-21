//
//  PasswordStrengthIndicator.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftUI

// MARK: - Password Strength Indicator
struct PasswordStrengthIndicator: View {
  let password: String

  private var strength: PasswordStrength {
    if password.isEmpty { return .none }
    if password.count < 6 { return .weak }
    if password.count < 8 { return .medium }

    var score = 0
    if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
    if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
    if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
    if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()"))
      != nil
    {
      score += 1
    }

    switch score {
    case 0...1: return .weak
    case 2...3: return .medium
    default: return .strong
    }
  }

  var body: some View {
    if !password.isEmpty {
      HStack(spacing: 4) {
        ForEach(0..<4, id: \.self) { index in
          Rectangle()
            .frame(height: 4)
            .foregroundColor(
              index < strength.level ? strength.color : Color.gray.opacity(0.3)
            )
            .cornerRadius(2)
        }

        Spacer()

        Text(strength.text)
          .font(.caption2)
          .foregroundColor(strength.color)
      }
    }
  }
}

enum PasswordStrength {
  case none, weak, medium, strong

  var level: Int {
    switch self {
    case .none: return 0
    case .weak: return 1
    case .medium: return 2
    case .strong: return 4
    }
  }

  var color: Color {
    switch self {
    case .none: return .clear
    case .weak: return .red
    case .medium: return .orange
    case .strong: return .green
    }
  }

  var text: String {
    switch self {
    case .none: return ""
    case .weak: return "Fraca"
    case .medium: return "Média"
    case .strong: return "Forte"
    }
  }
}
