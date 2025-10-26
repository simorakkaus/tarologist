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
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.clientName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        
        NavigationStack {
            
            if isLoading {
                Spacer()
                ProgressView("Загрузка гаданий...") // вот тут покрасивше надо переписать
                Spacer()
            } else if let error = errorMessage { // это тоже переписать покрасивше + добавить CTA что делать, кроме "Повторить"
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text("Ошибка загрузки")
                        .font(.headline)

                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Повторить") {
                        fetchSessions()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            }
            
            List {
                ForEach(filteredSessions) { session in
                    SessionCardView(session: session)
                }
            }
            .listStyle(.plain)
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
            self.errorMessage = "Пользователь не авторизован"
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
                    }
                case .failure(let error):
                    print("Ошибка получения сессий: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
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
            self.errorMessage = "Пользователь не авторизован"
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
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
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
                // Обновляем сессию в локальном массиве
                if let index = self.sessions.firstIndex(where: { $0.id == session.id }) {
                    self.sessions[index] = updatedSession
                }
            case .failure(let error):
                print("Ошибка обновления сессии: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Session Card View

struct SessionCardView: View {
    let session: TarotSession
    @State private var showActionMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок и меню
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    
                    HStack {
                        Text(session.clientName)
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
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
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
