//
//  OnBoardingTipView.swift
//  MeinGeld
//
//  Created by Roberto Edgar Geiss on 26/07/25.
//

import SwiftUI

struct OnboardingTipView: View {
  let title: String
  let tips: [String]
  let iconColor: Color

  init(
    title: String = "Dicas para começar",
    tips: [String],
    iconColor: Color = .yellow
  ) {
    self.title = title
    self.tips = tips
    self.iconColor = iconColor
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "lightbulb.fill")
          .foregroundColor(.yellow)
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
      }

      ForEach(tips, id: \.self) { tip in
        HStack(alignment: .top, spacing: 8) {
          Text("•")
            .foregroundColor(.secondary)
            .font(.subheadline)
          Text(tip)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .padding(.horizontal)
  }
}
