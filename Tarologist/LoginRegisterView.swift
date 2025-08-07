//
//  LoginRegisterView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth

/// Универсальный экран входа и регистрации.
/// Вызывает `onLoginSuccess`, если вход или регистрация прошли успешно.
struct LoginRegisterView: View {
    var onLoginSuccess: () -> Void

    @State private var login = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text(isLoginMode ? "Вход" : "Регистрация")
                .font(.title)
                .padding(.top)

            // Логин (на самом деле просто имя пользователя, email подставляется автоматически)
            TextField("Логин", text: $login)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            // Пароль
            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Сообщение об ошибке
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            // Кнопка входа или регистрации
            Button(isLoginMode ? "Войти" : "Зарегистрироваться") {
                authenticateUser()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            // Смена режима
            Button(isLoginMode ? "Нет аккаунта? Зарегистрироваться" : "Уже есть аккаунт? Войти") {
                isLoginMode.toggle()
                errorMessage = nil
            }

            // Кнопка "Нужна помощь"
            Button("Нужна помощь?") {
                contactSupport()
            }
            .padding(.top, 10)
        }
        .padding()
    }

    // MARK: - Аутентификация

    private func authenticateUser() {
        let email = login + "@example.com"

        if isLoginMode {
            // Вход
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    onLoginSuccess()
                }
            }
        } else {
            // Регистрация
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    onLoginSuccess()
                }
            }
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
