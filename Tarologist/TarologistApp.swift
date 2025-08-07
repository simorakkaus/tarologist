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

/// Главная точка входа приложения. Инициализирует Firebase и запускает `ContentView`.
@main
struct TarologistApp: App {
    /// Используем UIApplicationDelegate для настройки Firebase.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// AppDelegate нужен для настройки Firebase (и в будущем — пушей и др.)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Настройка Firebase
        FirebaseApp.configure()
        
        // Настройка Firestore с кешем
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings

        return true
    }
}

