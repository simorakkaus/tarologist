//
//  LaunchScreenView.swift
//  Tarologist
//
//  Created by Simo on 07.08.2025.
//

import SwiftUI

/// Кастомный экран загрузки после старта приложения.
/// Показывает логотип и "анимированную" надпись Загрузка...
struct LoadingScreenView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.wiggle.forward.byLayer, options: .repeat(.periodic(delay: 1.0)))
            Text("Загрузка...")
                .font(.body)
                .fontWeight(.bold)
            Spacer()
        }
    }
}

#Preview {
    LoadingScreenView()
}

