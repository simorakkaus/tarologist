//
//  ContentView.swift
//  Tarologist
//
//  Created by Simo on 05.08.2025.
//

import SwiftUI
import FirebaseAuth

/// Корневой экран, определяет, что показывать: экран загрузки, авторизацию или основной интерфейс
struct ContentView: View {
    /// Показываем ли главный интерфейс? (true, если пользователь вошел)
    @State private var isLoggedIn: Bool = false
    /// Показываем ли экран загрузки
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                LaunchScreenView()
            } else if isLoggedIn {
                MainTabView()
            } else {
                LoginRegisterView {
                    isLoggedIn = true
                }
            }
        }
        .onAppear {
            // Показываем экран загрузки 2 секунды, затем проверяем авторизацию
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoggedIn = Auth.auth().currentUser != nil
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
