//
//  ContentView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    private let authManager = AuthenticationManager.shared
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}
