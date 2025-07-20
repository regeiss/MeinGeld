//
//  AuthenticationView.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 16/07/25.
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isSignUp = false
    @State private var animateTransition = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .scaleEffect(animateTransition ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animateTransition)
                        
                        Text("MeinGeld")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Gerencie suas finanças de forma inteligente e segura")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Forms Container
                    VStack(spacing: 20) {
                        // Tab Selector
                        HStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp = false
                                }
                            }) {
                                Text("Entrar")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(!isSignUp ? Color.blue : Color.clear)
                                    .foregroundColor(!isSignUp ? .white : .blue)
                            }
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp = true
                                }
                            }) {
                                Text("Cadastrar")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(isSignUp ? Color.blue : Color.clear)
                                    .foregroundColor(isSignUp ? .white : .blue)
                            }
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Forms
                        Group {
                            if isSignUp {
                                SignUpView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                SignInView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            AuthenticationManager.shared.setModelContext(modelContext)
            animateTransition = true
        }
    }
}
