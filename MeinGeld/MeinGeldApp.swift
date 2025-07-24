//
//  MeinGeldApp.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import FirebaseCore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {

}

@main
struct PersonalFinanceApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  private let dataService: DataService
  private let firebaseService = FirebaseService.shared

  init() {
    // Configura Firebase primeiro
    firebaseService.configure()

    do {
      self.dataService = try DataService()
    } catch {
      ErrorManager.shared.handle(error, context: "PersonalFinanceApp.init")
      fatalError("Falha ao inicializar DataService: \(error)")
    }
  }
  // MARK: - Dependency Container
  private let container: DependencyContainer = AppDependencyContainer()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .inject(container)
        .modelContainer(container.dataService.getModelContainer())
        .task {
          await setupApp()
        }
        .onReceive(
          NotificationCenter.default.publisher(
            for: UIApplication.didEnterBackgroundNotification
          )
        ) { _ in
          container.firebaseService.logEvent(.appBackground)
        }
        .onReceive(
          NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
          )
        ) { _ in
          container.firebaseService.logEvent(.appForeground)
        }
    }
  }

  private func setupApp() async {
    do {
      // Setup managers with proper dependencies
      if let authManager = container.authManager as? AuthenticationManager {
        authManager.setModelContext(container.dataService.getMainContext())
      }

      // Generate sample data if needed
      try await container.dataService.generateSampleData()
    } catch {
      container.errorManager.handle(
        error,
        context: "PersonalFinanceApp.setupApp"
      )
    }
  }
}

//@main
//struct PersonalFinanceApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    private let dataService: DataService
//    private let firebaseService = FirebaseService.shared
//
//    init() {
//        // Configura Firebase primeiro
//        firebaseService.configure()
//
//        do {
//            self.dataService = try DataService()
//        } catch {
//            ErrorManager.shared.handle(error, context: "PersonalFinanceApp.init")
//            fatalError("Falha ao inicializar DataService: \(error)")
//        }
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .modelContainer(dataService.getModelContainer())
//                .task {
//                    // Setup managers
//                    AuthenticationManager.shared.setModelContext(dataService.getModelContainer().mainContext)
//
//                    do {
//                        try await dataService.generateSampleData()
//                    } catch {
//                        ErrorManager.shared.handle(error, context: "PersonalFinanceApp.generateSampleData")
//                    }
//                }
//                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
//                    firebaseService.logEvent(.appBackground)
//                }
//                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//                    firebaseService.logEvent(.appForeground)
//                }
//        }
//    }
//}
