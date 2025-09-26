//
//  ProfileView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Экран профиля: показывает текущего пользователя, статус подписки (заглушка) и даёт выйти из аккаунта.
/// НЕ использует fullScreenCover для логина — роутинг делает RootViewSwitcher через @AppStorage.
struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var isSubscribed = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentLogin: String = "—"

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                LoadingScreenView()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)

                Text("Пользователь: \(currentLogin)")
                    .font(.title2)

                Divider().padding(.vertical, 8)

                if isSubscribed {
                    Text("Подписка активна ✅")
                        .foregroundColor(.green)
                        .font(.headline)
                } else {
                    Text("Подписка неактивна ❌")
                        .foregroundColor(.red)
                        .font(.headline)

                    Button("Оформить подписку") {
                        // TODO: Запуск платежного флоу
                        // startPaymentFlow()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(role: .destructive) {
                    logout()
                } label: {
                    Text("Выйти из аккаунта")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .onAppear {
            loadProfile()
        }
    }

    // MARK: - Логика экрана

    private func loadProfile() {
        isLoading = true
        errorMessage = nil

        guard let user = Auth.auth().currentUser else {
            // Если по какой-то причине нет пользователя – сразу роняем isLoggedIn.
            isLoggedIn = false
            isLoading = false
            return
        }

        // Обновим пользователя с сервера, чтобы исключить рассинхрон после удалений/смены.
        user.reload { error in
            if let error = error {
                self.errorMessage = "Не удалось обновить профиль: \(error.localizedDescription)"
            }
            let email = Auth.auth().currentUser?.email ?? ""
            self.currentLogin = email.replacingOccurrences(of: "@example.com", with: "").isEmpty ? "—" : email.replacingOccurrences(of: "@example.com", with: "")

            // Заглушка подписки — здесь можно подтянуть данные из Firestore.
            // checkSubscription() // когда реализуешь UserService

            self.isLoading = false
        }
    }

    private func logout() {
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            // Сбросим локальные состояния.
            isSubscribed = false
            currentLogin = "—"
            // RootViewSwitcher сам переключит на LoginRegisterView, т.к. стоит listener + @AppStorage
            isLoggedIn = false
        } catch {
            errorMessage = "Не удалось выйти из аккаунта: \(error.localizedDescription)"
        }
    }
}

