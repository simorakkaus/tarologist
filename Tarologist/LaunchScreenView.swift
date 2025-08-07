//
//  LaunchScreenView.swift
//  Tarologist
//
//  Created by Simo on 07.08.2025.
//

import SwiftUI

/// Кастомный экран загрузки после старта приложения.
/// Показывает логотип и "анимированную" надпись Загрузка...
struct LaunchScreenView: View {
    @State private var loadingText = "Загрузка"
    @State private var dotCount = 0
    private let maxDots = 3
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Таролог")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(loadingText)\(String(repeating: ".", count: dotCount))")
                .font(.title3)
                .foregroundColor(.gray)
                .animation(.easeInOut, value: dotCount)

            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % (maxDots + 1)
        }
    }
}
