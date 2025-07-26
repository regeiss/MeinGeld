//
//  ToastView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct ToastView: View {
  let message: String
  let type: ToastType
  @Binding var isShowing: Bool

  enum ToastType {
    case success, error, info

    var color: Color {
      switch self {
      case .success: return DesignTokens.Colors.success
      case .error: return DesignTokens.Colors.danger
      case .info: return DesignTokens.Colors.primary
      }
    }

    var icon: String {
      switch self {
      case .success: return "checkmark.circle.fill"
      case .error: return "exclamationmark.circle.fill"
      case .info: return "info.circle.fill"
      }
    }
  }

  var body: some View {
    HStack {
      Image(systemName: type.icon)
        .foregroundColor(type.color)

      Text(message)
        .font(DesignTokens.Typography.body)
        .foregroundColor(DesignTokens.Colors.text)

      Spacer()

      Button("Fechar") {
        withAnimation {
          isShowing = false
        }
      }
      .font(DesignTokens.Typography.caption)
      .foregroundColor(type.color)
    }
    .padding(DesignTokens.Spacing.md)
    .background(DesignTokens.Colors.surface)
    .cornerRadius(DesignTokens.Border.radius)
    .shadow(radius: 4)
    .padding(.horizontal, DesignTokens.Spacing.md)
  }
}
