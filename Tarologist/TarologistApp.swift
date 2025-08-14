//
//  TarologistApp.swift
//  Tarologist
//
//  Created by Simo on 05.08.2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Главная точка входа приложения. Инициализирует Firebase и запускает RootViewSwitcher.
@main
struct TarologistApp: App {
    /// Используем UIApplicationDelegate для настройки Firebase (и при желании пушей).
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootViewSwitcher()
        }
    }
}

/// AppDelegate – конфигурация Firebase (и пр. интеграций на старте).
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 1) Firebase
        FirebaseApp.configure()

        // 2) Firestore persistent cache (новый API, без deprecated полей)
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings() // кэш оффлайн-данных
        Firestore.firestore().settings = settings

        return true
    }
}

/// Корневой роутер: показывает либо главный интерфейс, либо экран логина.
/// Синхронизируется с Firebase Auth через addStateDidChangeListener и @AppStorage.
struct RootViewSwitcher: View {
    /// Единый флаг авторизации во всём приложении.
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    /// Локальная загрузка при старте (пока обновляем состояние пользователя).
    @State private var isLoading: Bool = true

    /// Хэндл для Firebase Auth listener'а.
    @State private var authHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.4)
                    Text("Загрузка…")
                        .font(.headline)
                }
            } else {
                if isLoggedIn {
                    MainTabView()
                } else {
                    LoginRegisterView() {
                        // На случай прямого вызова onLoginSuccess – продублируем установку флага.
                        isLoggedIn = true
                    }
                }
            }
        }
        .onAppear {
            // 1) Ставим слушатель состояния авторизации – отработает при логине/логауте/рефреше токена.
            authHandle = Auth.auth().addStateDidChangeListener { _, user in
                isLoggedIn = (user != nil)
            }

            // 2) На старте аккуратно синхронизируем локальную сессию с сервером.
            if let user = Auth.auth().currentUser {
                user.reload { _ in
                    // Если reload упал – SDK сам сбросит currentUser при следующем событии, но нам нужно убрать лоадер:
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
        .onDisappear {
            // Чистим listener (на всякий).
            if let handle = authHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authHandle = nil
            }
        }
    }
}

