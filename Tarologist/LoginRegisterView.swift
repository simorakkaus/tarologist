//
//  LoginRegisterView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth

/// Экран входа и регистрации с использованием псевдо-email для соблюдения требований к персональным данным.
/// Восстановление доступа осуществляется через обращение в поддержку.
struct LoginRegisterView: View {
    // MARK: - Environment Properties
    @EnvironmentObject private var authManager: AuthManager
    
    // MARK: - State Properties
    @State private var login = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSupportOptions = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Заголовок экрана
                Text(isLoginMode ? "Вход" : "Регистрация")
                    .font(.title)
                    .padding(.top)
                
                // Поле ввода логина
                TextField("Логин", text: $login)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onChange(of: login) { _ in
                        errorMessage = nil
                    }
                
                // Поле ввода пароля
                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: password) { _ in
                        errorMessage = nil
                    }
                
                // Отображение ошибок
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Кнопка входа/регистрации
                Button(action: authenticateUser) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isLoginMode ? "Войти" : "Зарегистрироваться")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || !isFormValid)
                
                // Переключение между режимами входа и регистрации
                Button(isLoginMode ? "Нет аккаунта? Зарегистрироваться" : "Уже есть аккаунт? Войти") {
                    switchAuthMode()
                }
                
                // Кнопка восстановления доступа (только в режиме входа)
                if isLoginMode {
                    Button("Забыли пароль?") {
                        showSupportOptions.toggle()
                    }
                    .padding(.top, 10)
                    .confirmationDialog("Восстановление доступа", isPresented: $showSupportOptions) {
                        Button("Восстановить через поддержку") {
                            requestAccessRecovery()
                        }
                        Button("Связаться с поддержкой") {
                            contactSupport()
                        }
                        Button("Отмена", role: .cancel) {}
                    } message: {
                        Text("Выберите способ восстановления доступа к аккаунту")
                    }
                }
                
                // Кнопка связи с поддержкой
                Button("Нужна помощь?") {
                    contactSupport()
                }
                .padding(.top, 10)
                .opacity(isLoading ? 0.5 : 1.0)
                .disabled(isLoading)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Computed Properties
    /// Проверяет валидность формы
    private var isFormValid: Bool {
        !login.isEmpty && password.count >= 6
    }
    
    // MARK: - Authentication Methods
    
    /// Переключает режим между входом и регистрацией
    private func switchAuthMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }
    
    /// Аутентифицирует пользователя (вход или регистрация)
    private func authenticateUser() {
        guard validateFields() else { return }
        
        // Создаем псевдо-email для работы с Firebase Auth
        let email = generatePseudoEmail()
        errorMessage = nil
        isLoading = true
        
        if isLoginMode {
            // Вход существующего пользователя
            Auth.auth().signIn(withEmail: email, password: password) { _, error in
                self.handleAuthResult(error: error)
            }
        } else {
            // Регистрация нового пользователя
            Auth.auth().createUser(withEmail: email, password: password) { _, error in
                self.handleAuthResult(error: error)
            }
        }
    }
    
    /// Генерирует псевдо-email на основе логина
    private func generatePseudoEmail() -> String {
        // Используем домен example.com, который зарезервирован для примеров и не требует реальной доставки почты
        return "\(login)@example.com"
    }
    
    /// Обрабатывает результат аутентификации
    private func handleAuthResult(error: Error?) {
        isLoading = false
        
        if let error = error {
            self.errorMessage = error.localizedDescription
            return
        }
        
        // SessionManager автоматически обновит состояние через свой слушатель Auth
    }
    
    /// Проверяет валидность введенных данных
    private func validateFields() -> Bool {
        guard !login.isEmpty else {
            errorMessage = "Введите логин"
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Пароль должен содержать не менее 6 символов"
            return false
        }
        
        return true
    }
    
    // MARK: - Access Recovery Methods
    
    /// Открывает почтовый клиент для запроса восстановления доступа
    private func requestAccessRecovery() {
        let subject = "Восстановление доступа к аккаунту: \(login)"
        let body = """
        Здравствуйте!
        
        Я потерял доступ к своему аккаунту в приложении Таролог.
        Логин: \(login)
        
        Пожалуйста, помогите восстановить доступ к моему аккаунту.
        
        С уважением,
        Пользователь приложения Таролог
        """
        
        openEmailClient(subject: subject, body: body)
    }
    
    /// Открывает почтовый клиент для связи с поддержкой
    private func contactSupport() {
        let subject = "Вопрос по работе приложения Таролог"
        let body = """
        Здравствуйте!
        
        У меня возник вопрос по работе приложения Таролог.
        Пожалуйста, предоставьте необходимую помощь.
        
        С уважением,
        Пользователь приложения Таролог
        """
        
        openEmailClient(subject: subject, body: body)
    }
    
    /// Открывает почтовый клиент с подготовленным письмом
    private func openEmailClient(subject: String, body: String) {
        let email = "mailto:support@tarologist.app?subject=\(subject)&body=\(body)"
        
        if let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedEmail) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginRegisterView()
        .environmentObject(AuthManager())
}
