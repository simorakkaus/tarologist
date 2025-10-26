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
    
    var body: some View {
        ZStack {
            if let errorMessage = errorMessage {
                // Показываем ErrorView при ошибке
                ErrorView.authError(onRetry: {
                    // Просто скрываем ошибку - это правильный подход
                    self.errorMessage = nil
                })
            }
            else {
                // Основной контент
                mainContentView
            }
            
            // Загрузочный экран поверх всего
            if isLoading {
                LoadingScreenView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - View Components
    private var mainContentView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "moon.stars.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .symbolEffect(.bounce, options: .nonRepeating)
                    .symbolEffect(.bounce, options: .nonRepeating, value: isLoginMode)
                
                Form {
                    Section {
                        TextField(isLoginMode ? "Логин" : "Придумайте логин для входа", text: $login)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onChange(of: login) { _ in
                                errorMessage = nil
                            }
                        SecureField(isLoginMode ? "Пароль" : "Придумайте пароль", text: $password)
                            .onChange(of: password) { _ in
                                errorMessage = nil
                            }
                    }
                    footer: {
                        if isLoginMode {
                            Button("Забыли пароль?") {
                                requestAccessRecovery()
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
            .blur(radius: isLoading ? 3 : 0)
            .allowsHitTesting(!isLoading)
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
        withAnimation {
            isLoginMode.toggle()
        }
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
            // Преобразуем Firebase ошибки в понятные сообщения
            self.errorMessage = getAuthErrorMessage(error)
            return
        }
    }
    
    // MARK: - Error Handling
    private func getAuthErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
            case 17008: // INVALID_EMAIL
                return "Некорректный формат логина"
            case 17009: // WRONG_PASSWORD
                return "Неверный пароль"
            case 17011: // USER_NOT_FOUND
                return "Пользователь с таким логином не найден"
            case 17007: // EMAIL_ALREADY_IN_USE
                return "Пользователь с таким логином уже существует"
            case 17020: // NETWORK_ERROR
                return "Ошибка сети. Проверьте подключение к интернету"
            case 17005: // USER_DISABLED
                return "Аккаунт заблокирован"
            case 17010: // TOO_MANY_REQUESTS
                return "Слишком много попыток. Попробуйте позже"
            default:
                return "Произошла ошибка: \(error.localizedDescription)"
        }
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
        
        let deviceInfo = DeviceInfoService.getDeviceInfo()
        
        let subject = "Восстановление доступа к аккаунту: \(login)"
        let body = """
        Здравствуйте!
        
        Не могу получить доступ к своему аккаунту в приложении Таролог.
        Логин: \(login)
        
        Пожалуйста, помогите восстановить доступ к моему аккаунту.
        
        \(deviceInfo)
        
        С уважением,
        Пользователь приложения Таролог
        """
        
        openEmailClient(subject: subject, body: body)
    }
    
    /// Открывает почтовый клиент для связи с поддержкой
    private func contactSupport() {
        
        let deviceInfo = DeviceInfoService.getDeviceInfo()
        
        let subject = "Вопрос по работе приложения Таролог"
        let body = """
        Здравствуйте!
        
        У меня возник вопрос по работе приложения Таролог.
        
        ОПИШИТЕ ВАШУ ПРОБЛЕМУ
        ПО ВОЗМОЖНОСТИ ПРЕДОСТАВЬТЕ СКРИНШОТ
        
        Пожалуйста, предоставьте необходимую помощь.
        
        \(deviceInfo)
        
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
