//
//  AuthScreen.swift
//  Tarologist
//
//  Created by Simo on 26.09.2025.
//

import SwiftUI

struct AuthScreen: View {
    // MARK: - Состояние для текстовых полей и переключения между входом/регистрацией
    @State private var login = ""
    @State private var password = ""
    @State private var isLoginMode = true
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Секция с формой
                Section {
                    TextField("Email или логин", text: $login)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Пароль", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Учетные данные")
                } footer: {
                    // CTA-кнопка "Забыли пароль?"
                    Button("Нужна помощь? Забыли пароль?") {
                        // Обработка нажатия на "Забыли пароль?"
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // MARK: - Основная кнопка действия
                Section {
                    Button(action: {
                        // Бизнес-логика входа или регистрации
                    }) {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Войти" : "Зарегистрироваться")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent) // Системный стиль выделенной кнопки
                }
                
                // MARK: - Секция для переключения режима
                Section {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLoginMode.toggle()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Нет аккаунта? Зарегистрироваться" : "Уже есть аккакунт? Войти")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .navigationTitle(isLoginMode ? "Вход" : "Регистрация") // Динамический заголовок
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Превью для Xcode
#Preview {
    AuthScreen()
}
