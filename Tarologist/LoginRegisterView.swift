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
    
    var body: some View {
        ZStack {
            // Основной контент
            NavigationStack {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "moon.stars.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Form {
                        Section {
                            TextField("Логин", text: $login)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .onChange(of: login) { _ in
                                    errorMessage = nil
                                }
                            SecureField("Пароль", text: $password)
                                .onChange(of: password) { _ in
                                    errorMessage = nil
                                }
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        footer: {
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
                        }
                        .listRowBackground(Color(.systemGroupedBackground))
                    }
                    .frame(height: 180)
                    .scrollDisabled(true)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    
                    Button(action: authenticateUser) {
                        Text(isLoginMode ? "Войти" : "Зарегистрироваться")
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .disabled(isLoading || !isFormValid)
                    
                    Button(isLoginMode ? "Нет аккаунта? Зарегистрироваться" : "Уже есть аккаунт? Войти") {
                        switchAuthMode()
                    }
                    .padding(.top, 10)
                    .disabled(isLoading)
                    
                    Spacer()
                }
                .navigationTitle(isLoginMode ? "Вход" : "Регистрация")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Нужна помощь?") {
                            contactSupport()
                        }
                    }
                }
            }
            .blur(radius: isLoading ? 3 : 0) // Размываем контент при загрузке
            .allowsHitTesting(!isLoading) // Блокируем взаимодействие при загрузке
            
            // Полноэкранный загрузочный экран
            if isLoading {
                LoadingScreenView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
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
        let email = "mailto:support@tarologist.app?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: email) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginRegisterView()
        .environmentObject(AuthManager())
}
