//
//  WelcomeSectionView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 20/07/25.
//

import Foundation
import SwiftUI

struct WelcomeSection: View {
  @Environment(\.dependencies) private var container

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("Olá, \(container.authManager.currentUser?.name ?? "Usuário")!")
          .font(.title2)
          .fontWeight(.semibold)

        Text("Bem-vindo de volta")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Profile Image
      Group {
        if let imageData = container.authManager.currentUser?.profileImageData,
          let uiImage = UIImage(data: imageData)
        {
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Image(systemName: "person.circle.fill")
            .font(.system(size: 35))
            .foregroundColor(.blue)
        }
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())
    }
    .padding(.horizontal)
  }
}
