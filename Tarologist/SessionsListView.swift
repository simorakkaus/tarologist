//
//  SessionsListView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Экран списка прошлых сессий гадания
struct SessionsListView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var sessions: [TarotSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var listener: ListenerRegistration?
    @State private var selectedSession: TarotSession?
    @State private var showSessionDetail = false
    
    // Фильтрация по статусу отправки
    enum FilterType {
        case all, sent, notSent
    }
    
    @State private var filterType: FilterType = .all
    
    var filteredSessions: [TarotSession] {
        let filtered = sessions.filter { session in
            switch filterType {
            case .all: return true
            case .sent: return session.isSent
            case .notSent: return !session.isSent
            }
        }
        
        guard !searchText.isEmpty else { return filtered }
        
        let searchLower = searchText.lowercased()
        
        return filtered.filter { session in
            // Массив всех текстовых полей для поиска
            let searchableStrings = [
                session.clientName,
                session.clientAge,
                session.spreadName,
                session.questionCategoryName,
                session.questionText,
                session.interpretation
            ].compactMap { $0 } + getDateSearchStrings(session.date)
            
            return searchableStrings.contains { $0.lowercased().contains(searchLower) }
        }
    }

    // Вспомогательная функция для получения даты в разных форматах
    private func getDateSearchStrings(_ date: Date) -> [String] {
        let dateFormats = [
            "dd.MM.yyyy",   // 20.10.2025
            "dd.MM.yy",     // 20.10.25
            "MM.yyyy",      // 10.2025
            "yyyy",         // 2025
            "MMMM yyyy",    // октябрь 2025
            "MMMM",         // октябрь
            "EEEE"          // понедельник
        ]
        
        return dateFormats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Основной контент - показываем только когда нет ошибки и загрузки
                if !isLoading && errorMessage == nil {
                    List {
                        ForEach(filteredSessions) { session in
                            SessionCardView(session: session)
                        }
                    }
                    
                }
                
                // Состояние загрузки
                if isLoading {
                    LoadingView()
                }
                
                // Состояние ошибки
                if let errorMessage = errorMessage, !isLoading {
                    ErrorView.sessionsLoadingError(
                        onRetry: {
                            fetchSessions()
                        }
                    )
                }
            }
            .navigationTitle("Мои расклады")
            .refreshable {
                fetchSessions()
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Поиск раскладов"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Кнопка новой сессии
                    NavigationLink(destination: ClientInputView()) {
                        Image(systemName: "moon.stars.circle.fill")
                            .font(.system(size: 26))
                            .frame(width: 56, height: 56)
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.bounce, options: .nonRepeating)
                    }
                }
            }
        }
        .onAppear {
            startListening()
        }
        .onDisappear {
            stopListening()
        }
    }
    
    // MARK: - Real-time Listener
    
    private func startListening() {
        guard let userID = authManager.getCurrentUserId() else {
            self.errorMessage = "Пользователь не авторизован. Пожалуйста, войдите в систему."
            self.isLoading = false
            print("Ошибка: пользователь не авторизован")
            return
        }
        
        isLoading = true
        errorMessage = nil
        print("Запуск слушателя для пользователя: \(userID)")
        
        // Останавливаем предыдущий listener, если он есть
        stopListening()
        
        // Запускаем real-time listener
        listener = SessionManager.shared.startSessionsListener(for: userID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sessions):
                    print("Успешно получено \(sessions.count) сессий")
                    withAnimation {
                        self.sessions = sessions
                        self.errorMessage = nil
                    }
                case .failure(let error):
                    print("Ошибка получения сессий: \(error.localizedDescription)")
                    self.errorMessage = self.getUserFriendlyErrorMessage(error)
                }
            }
        }
    }
    
    private func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Загрузка сессий из Firestore
    
    private func fetchSessions() {
        guard let userID = authManager.getCurrentUserId() else {
            self.errorMessage = "Пользователь не авторизован. Пожалуйста, войдите в систему."
            self.isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        SessionManager.shared.fetchSessions(for: userID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sessions):
                    withAnimation {
                        self.sessions = sessions
                        self.errorMessage = nil
                    }
                case .failure(let error):
                    self.errorMessage = self.getUserFriendlyErrorMessage(error)
                }
            }
        }
    }
    
    // MARK: - Обработка ошибок
    
    /// Преобразует технические ошибки в понятные пользователю сообщения
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        
        // Ошибки сети
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return "Отсутствует подключение к интернету. Пожалуйста, проверьте ваше соединение."
            case NSURLErrorTimedOut:
                return "Превышено время ожидания ответа от сервера. Пожалуйста, попробуйте снова."
            default:
                return "Проблема с сетью. Пожалуйста, проверьте подключение к интернету."
            }
        }
        
        // Ошибки Firestore
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: // PERMISSION_DENIED
                return "У вас нет прав для доступа к этим данным. Пожалуйста, войдите в систему."
            case 13: // INTERNAL
                return "Внутренняя ошибка сервера. Пожалуйста, попробуйте позже."
            default:
                return "Ошибка при загрузке данных. Пожалуйста, попробуйте снова."
            }
        }
        
        // Общие ошибки
        return error.localizedDescription
    }
    
    // MARK: - Действия с сессиями
    
    private func deleteSession(_ session: TarotSession) {
        guard let userID = authManager.getCurrentUserId() else { return }
        
        SessionManager.shared.deleteSession(session, for: userID) { result in
            switch result {
            case .success:
                // Удаляем сессию из локального массива
                withAnimation {
                    self.sessions.removeAll { $0.id == session.id }
                }
            case .failure(let error):
                print("Ошибка удаления сессии: \(error.localizedDescription)")
                // Здесь можно показать toast или alert об ошибке удаления
            }
        }
    }
    
    private func markAsSent(_ session: TarotSession) {
        guard let userID = authManager.getCurrentUserId() else { return }
        
        // Создаем новую сессию с isSent = true
        let updatedSession = TarotSession(
            id: session.id,
            clientName: session.clientName,
            clientAge: session.clientAge,
            date: session.date,
            spreadId: session.spreadId,
            spreadName: session.spreadName,
            questionCategoryId: session.questionCategoryId,
            questionCategoryName: session.questionCategoryName,
            questionText: session.questionText,
            interpretation: session.interpretation,
            isSent: true
        )
        
        SessionManager.shared.updateSession(updatedSession, for: userID) { result in
            switch result {
            case .success:
                // Обновляем сессию в локальном массива
                if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                    self.sessions[index] = updatedSession
                }
            case .failure(let error):
                print("Ошибка обновления сессии: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Загрузка гаданий...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Session Card View (без изменений)

struct SessionCardView: View {
    let session: TarotSession
    @State private var showActionMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок и меню
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    
                    HStack {
                        Text("\(session.clientName),")
                            .font(.headline)
                        
                        Text(session.clientAge ?? "")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Меню действий
                        Menu {
                            Button {
                                // Действие просмотра
                            } label: {
                                Label("Просмотр", systemImage: "eye")
                            }
                            
                            Button {
                                // Действие редактирования
                            } label: {
                                Label("Редактировать", systemImage: "pencil")
                            }
                            
                            Button {
                                // Действие отправки
                            } label: {
                                Label("Отправить", systemImage: "paperplane")
                            }
                            
                            Button(role: .destructive) {
                                // Действие удаления
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 44, height: 44)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    
                    // Категория вопроса
                    if let category = session.questionCategoryName {
                        Text(category)
                            .font(.headline)
                    }
                    
                    Text(session.spreadName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // Вопрос клиента
                    if let questionText = session.questionText, !questionText.isEmpty {
                        Text("Вопрос: \(questionText)")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                        .frame(height: 12)
                    
                    HStack {
                        Text("Дата расклада: ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(session.date, style: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Статус отправки: ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(session.isSent ? "Отправлено" : "Не отправлено")
                            .font(.caption)
                            .foregroundColor(session.isSent ? .green : .orange)
                    }
                    
                    if session.isSent {
                        VStack {
                            HStack {
                                Text("Канал отправки: ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Inst, Tg, WA, Email") // Заглушка
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                            }
                            HStack {
                                Text("Способ отправки: ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Текст, Голос, Видео") // Заглушка
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    SessionsListView()
        .environmentObject(AuthManager())
}

#Preview("Состояние загрузки") {
    SessionsListView()
        .environmentObject(AuthManager())
}


