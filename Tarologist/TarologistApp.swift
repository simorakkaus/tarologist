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

@main
struct TarologistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootViewSwitcher()
                .environmentObject(authManager)
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

struct RootViewSwitcher: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingScreenView()
            } else {
                if authManager.isLoggedIn {
                    MainTabView()
                } else {
                    LoginRegisterView()
                }
            }
        }
    }
}

