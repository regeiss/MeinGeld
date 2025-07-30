//
//  DependencyContainer.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
import SwiftUI

// MARK: - Enhanced Dependency Container
protocol DependencyContainer {
  var authManager: any AuthenticationManagerProtocol { get }
    var firebaseService: FirebaseServiceProtocol { get }
    var errorManager: ErrorManagerProtocol { get }
    var dataService: DataServiceProtocol { get }
    var themeManager: ThemeManager { get }
}

// MARK: - Production Container
final class AppDependencyContainer: DependencyContainer {
    
    // MARK: - Lazy Properties
    lazy var errorManager: ErrorManagerProtocol = ErrorManager.shared
    lazy var firebaseService: FirebaseServiceProtocol = FirebaseService.shared
    lazy var themeManager: ThemeManager = ThemeManager.shared
    
    lazy var dataService: DataServiceProtocol = {
        do {
            return try DataService()
        } catch {
            fatalError("Failed to initialize DataService: \(error)")
        }
    }()
    
  lazy var authManager: any AuthenticationManagerProtocol = {
        let manager = AuthenticationManager.shared
        Task { @MainActor in
            manager.setModelContext(dataService.getMainContext())
        }
        return manager
    }()
    
    // MARK: - Environment Key
    struct DependencyContainerKey: EnvironmentKey {
        static let defaultValue: DependencyContainer = AppDependencyContainer()
    }
}

// Usar em Views
//struct TransactionsView: View {
//    private let container: DependencyContainer
//
//    init(container: DependencyContainer) {
//        self.container = container
//    }
//
//    var body: some View {
//        // Implementação
//    }
//}
//
//// No App principal
//@main
//struct PersonalFinanceApp: App {
//    private let container = AppDependencyContainer()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView(container: container)
//                .modelContainer(container.dataService.getModelContainer())
//        }
//    }

extension EnvironmentValues {
  var dependencies: DependencyContainer {
    get { self[AppDependencyContainer.DependencyContainerKey.self] }
    set { self[AppDependencyContainer.DependencyContainerKey.self] = newValue }
  }
}
