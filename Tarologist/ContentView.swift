import SwiftUI
import FirebaseAuth

/// Корневой экран, который определяет, куда перейти: в основной интерфейс или в авторизацию
struct ContentView: View {
    /// Показываем ли главный интерфейс? (true, если пользователь вошел)
    @State private var isLoggedIn: Bool = false
    /// Показываем ли индикатор загрузки
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                // Пока идёт загрузка — показываем спиннер и подпись
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Загрузка...")
                        .font(.headline)
                }
            } else {
                // После загрузки выбираем экран
                if isLoggedIn {
                    MainTabView()
                } else {
                    // Передаем замыкание, чтобы `LoginRegisterView` мог сообщить об успешном входе
                    LoginRegisterView {
                        isLoggedIn = true
                    }
                }
            }
        }
        .onAppear {
            // Показываем экран загрузки 2 секунды, затем проверяем авторизацию
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let user = Auth.auth().currentUser {
                    user.reload { error in
                        if let error = error {
                            print("User reload failed: \(error.localizedDescription)")
                            isLoggedIn = false
                        } else {
                            isLoggedIn = true
                        }
                        isLoading = false
                    }
                } else {
                    isLoggedIn = false
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

