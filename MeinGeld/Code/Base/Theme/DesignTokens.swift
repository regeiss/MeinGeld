//
//  DesignTokens.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftUI

// MARK: - Design Tokens
struct DesignTokens {
    // Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let success = Color.green
        static let danger = Color.red
        static let warning = Color.orange
        static let surface = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let text = Color.primary
        static let textSecondary = Color.secondary
    }
    
    // Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // Typography
    struct Typography {
        static let h1 = Font.largeTitle.weight(.bold)
        static let h2 = Font.title.weight(.semibold)
        static let h3 = Font.title2.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let small = Font.caption2
    }
    
    // Borders
    struct Border {
        static let radius: CGFloat = 12
        static let radiusSmall: CGFloat = 8
        static let radiusLarge: CGFloat = 16
        static let width: CGFloat = 1
    }
}

// MARK: - Custom Components

// Loading Button
struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return DesignTokens.Colors.primary
            case .secondary: return DesignTokens.Colors.secondary
            case .danger: return DesignTokens.Colors.danger
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(DesignTokens.Typography.body)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(style.backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.Border.radius)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1.0)
    }
}

// Card Component
struct Card<Content: View>: View {
    let content: () -> Content
    var padding: CGFloat = DesignTokens.Spacing.md
    var shadow: Bool = true
    
    init(padding: CGFloat = DesignTokens.Spacing.md, shadow: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.shadow = shadow
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.Border.radius)
        .shadow(color: shadow ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
    }
}

// Enhanced Text Field
struct EnhancedTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var validationError: String?
    var icon: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Label
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(DesignTokens.Colors.primary)
                        .frame(width: 20)
                }
                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            // Text Field
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .keyboardType(keyboardType)
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfaceSecondary)
            .cornerRadius(DesignTokens.Border.radiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Border.radiusSmall)
                    .stroke(
                        validationError != nil ? DesignTokens.Colors.danger : Color.clear,
                        lineWidth: DesignTokens.Border.width
                    )
            )
            
            // Error Message
            if let error = validationError {
                Text(error)
                    .font(DesignTokens.Typography.small)
                    .foregroundColor(DesignTokens.Colors.danger)
            }
        }
    }
}

// Empty State Component
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.secondary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.h3)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(DesignTokens.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// Toast/Snackbar Component
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

// Usage Examples
struct ExampleUsage: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var showToast = false
    @State private var emailError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Card Example
                Card {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Saldo Total")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("R$ 5.250,00")
                            .font(DesignTokens.Typography.h2)
                            .foregroundColor(DesignTokens.Colors.success)
                    }
                }
                
                // Enhanced Text Field Example
                EnhancedTextField(
                    title: "Email",
                    text: $email,
                    keyboardType: .emailAddress,
                    validationError: emailError,
                    icon: "envelope"
                )
                
                // Loading Button Example
                LoadingButton(
                    title: "Entrar",
                    isLoading: isLoading,
                    action: {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoading = false
                            showToast = true
                        }
                    }
                )
                
                // Empty State Example
                EmptyStateView(
                    title: "Nenhuma transação encontrada",
                    message: "Você ainda não tem nenhuma transação. Adicione uma para começar.",
                    systemImage: "list.bullet.rectangle",
                    actionTitle: "Adicionar Transação",
                    action: { print("Add transaction") }
                )
            }
            .padding(DesignTokens.Spacing.md)
        }
        .overlay(
            // Toast overlay
            VStack {
                if showToast {
                    ToastView(
                        message: "Login realizado com sucesso!",
                        type: .success,
                        isShowing: $showToast
                    )
                    .transition(.move(edge: .top))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                }
                Spacer()
            }
        )
    }
}
