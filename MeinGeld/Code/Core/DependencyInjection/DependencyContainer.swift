//
//  DependencyContainer.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import Foundation
// Protocolo para container de dependências
protocol DependencyContainer {
    var authManager: AuthenticationManagerProtocol { get }
    var firebaseService: FirebaseServiceProtocol { get }
    var errorManager: ErrorManagerProtocol { get }
    var dataService: DataServiceProtocol { get }
}

// Container principal
final class AppDependencyContainer: DependencyContainer {
    lazy var authManager: AuthenticationManagerProtocol = {
        AuthenticationManager(
            errorManager: errorManager,
            firebaseService: firebaseService
        )
    }()
    
    lazy var firebaseService: FirebaseServiceProtocol = FirebaseService.shared
    lazy var errorManager: ErrorManagerProtocol = ErrorManager.shared
    lazy var dataService: DataServiceProtocol = {
        try! DataService(errorManager: errorManager)
    }()
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
}
