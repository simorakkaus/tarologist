//
//  LoginRegisterView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth

/// Экран входа и регистрации.
/// Использует @AppStorage("isLoggedIn") как единый флаг авторизации.
/// При успехе вызывает `onLoginSuccess` (опционально) и поднимает флаг авторизации.
struct LoginRegisterView: View {
    /// Колбэк на случай, если родитель хочет отреагировать дополнительно.
    var onLoginSuccess: () -> Void = {}

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var login = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(isLoginMode ? "Вход" : "Регистрация")
                    .font(.title)
                    .padding(.top)

                // ЛОГИН (имя-псевдоemail – без персональных данных)
                TextField("Логин", text: $login)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                // ПАРОЛЬ
                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: authenticateUser) {
                    HStack {
                        if isLoading { ProgressView().padding(.trailing, 8) }
                        Text(isLoginMode ? "Войти" : "Зарегистрироваться")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || login.isEmpty || password.isEmpty)

                Button(isLoginMode ? "Нет аккаунта? Зарегистрироваться" : "Уже есть аккаунт? Войти") {
                    isLoginMode.toggle()
                    errorMessage = nil
                }

                Button("Нужна помощь?") {
                    contactSupport()
                }
                .padding(.top, 10)
                .opacity(isLoading ? 0.5 : 1.0)
                .disabled(isLoading)
            }
            .padding()
        }
    }

    // MARK: - Аутентификация

    private func authenticateUser() {
        // Конструируем псевдо-email (workaround без ПДн).
        let email = login + "@example.com"
        errorMessage = nil
        isLoading = true

        if isLoginMode {
            Auth.auth().signIn(withEmail: email, password: password) { _, error in
                handleAuthResult(error: error)
            }
        } else {
            Auth.auth().createUser(withEmail: email, password: password) { _, error in
                handleAuthResult(error: error)
            }
        }
    }

    private func handleAuthResult(error: Error?) {
        if let error = error {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return
        }

        // Обновим пользователя с сервера на всякий случай, затем поднимем флаг авторизации.
        Auth.auth().currentUser?.reload { _ in
            self.isLoggedIn = (Auth.auth().currentUser != nil)
            self.isLoading = false
            self.onLoginSuccess()
        }
    }

    // MARK: - Поддержка

    private func contactSupport() {
        let subject = "Проблема с регистрацией в Таролог"
        let body = "Здравствуйте, мне нужна помощь при регистрации в приложении."
        let email = "mailto:support@example.com?subject=\(subject)&body=\(body)"
        if let url = URL(string: email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            UIApplication.shared.open(url)
        }
    }
}

