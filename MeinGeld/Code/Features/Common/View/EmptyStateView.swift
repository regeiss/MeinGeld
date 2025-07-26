//
//  EmptyStateView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//
import SwiftUI

struct EmptyStateView: View {
  let icon: String
  let iconColor: Color
  let title: String
  let description: String
  let buttonTitle: String
  let buttonColor: Color
  let action: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      // Ícone principal
      Image(systemName: icon)
        .font(.system(size: 80))
        .foregroundColor(iconColor)
        .opacity(0.7)

      VStack(spacing: 16) {
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)

        Text(description)
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }

      Button(action: action) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text(buttonTitle)
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(buttonColor)
        .cornerRadius(10)
      }

      Spacer()
    }
    .padding()
  }
}
