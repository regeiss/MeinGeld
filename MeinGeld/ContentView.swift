//
//  ContentView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 19/07/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.dependencies) private var container

  var body: some View {
    Group {
      if container.authManager.isAuthenticated {
        MainTabView()
      } else {
        AuthenticationView()
      }
    }
    .preferredColorScheme(container.themeManager.currentTheme.colorScheme)
  }
}
