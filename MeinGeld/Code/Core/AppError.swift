//
//  AppError.swift
//  Financas pessoais
//
//  Created by Roberto Edgar Geiss on 13/07/25.
//

import Foundation
import FirebaseAuth

enum AppError: LocalizedError, Sendable {
  case dataNotFound
  case invalidAmount
  case accountNotFound
  case transactionCreationFailed
  case budgetExceeded(category: String, limit: Decimal)
  case networkError(underlying: Error)
  case authenticationFailed
  case userNotFound
  case invalidCredentials
  case emailAlreadyExists
  case emailNotVerified
  case userDisabled
  case tooManyRequests
  case operationNotAllowed
  case weakPassword
  case emailBadlyFormatted
  case userTokenExpired
  case networkUnavailable
  case internalError
  case unknown(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .dataNotFound:
        return "Dados não encontrados"
    case .invalidAmount:
        return "Valor inválido"
    case .accountNotFound:
        return "Conta não encontrada"
    case .transactionCreationFailed:
        return "Falha ao criar transação"
    case .budgetExceeded(let category, let limit):
        return "Orçamento da categoria \(category) excedido. Limite: \(limit)"
    case .networkError(let underlying):
        return "Erro de rede: \(underlying.localizedDescription)"
    case .authenticationFailed:
        return "Falha na autenticação"
    case .userNotFound:
        return "Usuário não encontrado"
    case .invalidCredentials:
        return "Email ou senha inválidos"
    case .emailAlreadyExists:
        return "Email já está em uso"
    case .unknown(let underlying):
        return "Erro desconhecido: \(underlying.localizedDescription)"
    
    // Firebase Auth specific errors
    case .emailNotVerified:
        return "Por favor, verifique seu email antes de fazer login"
    case .userDisabled:
        return "Sua conta foi desabilitada. Entre em contato com o suporte"
    case .tooManyRequests:
        return "Muitas tentativas de login. Tente novamente mais tarde"
    case .operationNotAllowed:
        return "Operação não permitida. Verifique as configurações"
    case .weakPassword:
        return "Senha muito fraca. Use pelo menos 6 caracteres"
    case .emailBadlyFormatted:
        return "Formato de email inválido"
    case .userTokenExpired:
        return "Sessão expirada. Faça login novamente"
    case .networkUnavailable:
        return "Sem conexão com a internet"
    case .internalError:
        return "Erro interno. Tente novamente"
    }
}

// MARK: - Firebase Auth Error Conversion
static func from(authError: AuthErrorCode) -> AppError {
    switch authError {
    case .emailAlreadyInUse:
        return .emailAlreadyExists
    case .userNotFound:
        return .userNotFound
    case .wrongPassword, .invalidCredential:
        return .invalidCredentials
    case .userDisabled:
        return .userDisabled
    case .tooManyRequests:
        return .tooManyRequests
    case .operationNotAllowed:
        return .operationNotAllowed
    case .weakPassword:
        return .weakPassword
    case .invalidEmail:
        return .emailBadlyFormatted
    case .userTokenExpired:
        return .userTokenExpired
    case .networkError:
        return .networkUnavailable
    case .internalError:
        return .internalError
    default:
        return .authenticationFailed
    }
}
}
