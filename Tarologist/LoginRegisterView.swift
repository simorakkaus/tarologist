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
            // Основной контент
            NavigationStack {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "moon.stars.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .symbolEffect(.wiggle.forward.byLayer, options: .nonRepeating, value: isLoginMode)
                    
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
        
        let deviceInfo = getDeviceInfo()
        
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
        
        let deviceInfo = getDeviceInfo()
        
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
    
    /// Возвращает строку с информацией об устройстве
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let deviceModel = getDeviceModel()
        let appVersion = getAppVersion()
        let currentDate = getCurrentDate()
        
        return """
        ---
        Информация об устройстве:
        Приложение: Таролог \(appVersion)
        Устройство: \(deviceModel)
        iOS: \(systemVersion)
        Дата: \(currentDate)
        """
    }

    /// Возвращает модель устройства
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Сопоставление идентификаторов с читаемыми названиями
        let deviceMapping = [
            "iPhone1,1": "iPhone", "iPhone1,2": "iPhone 3G", "iPhone2,1": "iPhone 3GS",
            "iPhone3,1": "iPhone 4", "iPhone3,2": "iPhone 4", "iPhone3,3": "iPhone 4",
            "iPhone4,1": "iPhone 4S", "iPhone5,1": "iPhone 5", "iPhone5,2": "iPhone 5",
            "iPhone5,3": "iPhone 5c", "iPhone5,4": "iPhone 5c", "iPhone6,1": "iPhone 5s",
            "iPhone6,2": "iPhone 5s", "iPhone7,1": "iPhone 6 Plus", "iPhone7,2": "iPhone 6",
            "iPhone8,1": "iPhone 6s", "iPhone8,2": "iPhone 6s Plus", "iPhone8,4": "iPhone SE",
            "iPhone9,1": "iPhone 7", "iPhone9,2": "iPhone 7 Plus", "iPhone9,3": "iPhone 7",
            "iPhone9,4": "iPhone 7 Plus", "iPhone10,1": "iPhone 8", "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X", "iPhone10,4": "iPhone 8", "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,6": "iPhone X", "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XS Max", "iPhone11,8": "iPhone XR", "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max", "iPhone12,8": "iPhone SE 2",
            "iPhone13,1": "iPhone 12 Mini", "iPhone13,2": "iPhone 12", "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max", "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 Mini", "iPhone14,5": "iPhone 13", "iPhone14,6": "iPhone SE 3",
            "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus", "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max", "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            
            // iPad
            "iPad4,1": "iPad Air", "iPad4,2": "iPad Air", "iPad4,3": "iPad Air",
            "iPad5,3": "iPad Air 2", "iPad5,4": "iPad Air 2", "iPad6,7": "iPad Pro 12.9\"",
            "iPad6,8": "iPad Pro 12.9\"", "iPad6,3": "iPad Pro 9.7\"", "iPad6,4": "iPad Pro 9.7\"",
            "iPad7,1": "iPad Pro 12.9\" 2gen", "iPad7,2": "iPad Pro 12.9\" 2gen",
            "iPad7,3": "iPad Pro 10.5\"", "iPad7,4": "iPad Pro 10.5\"",
            
            // Simulator
            "x86_64": "Simulator", "arm64": "Simulator"
        ]
        
        return deviceMapping[identifier] ?? identifier
    }

    /// Возвращает версию приложения
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    /// Возвращает текущую дату в формате строки
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    LoginRegisterView()
        .environmentObject(AuthManager())
}
