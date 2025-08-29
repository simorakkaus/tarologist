//
//  SessionManager.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthListener()
    }

    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
            self?.verifyUserToken(user)
        }
    }

    private func verifyUserToken(_ user: User?) {
        guard let user = user else {
            isLoading = false
            return
        }

        user.reload { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Token refresh error: \(error.localizedDescription)")
                    // Проверяем различные случаи невалидного токена
                    let nsError = error as NSError
                    if nsError.domain == AuthErrorDomain {
                        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
                            switch errorCode {
                            case .userTokenExpired, .userNotFound, .invalidUserToken:
                                try? Auth.auth().signOut()
                            default:
                                break
                            }
                        }
                    }
                }
                self?.isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Состояние isLoggedIn автоматически обновится через слушатель
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            // Можно добавить обработку ошибки выхода, если нужно
        }
    }
    
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
