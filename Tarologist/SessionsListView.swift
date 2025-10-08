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
    @State private var showingNewSession = false
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
    
//    var body: some View {
//        
//    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Кастомная навигационная панель
                HStack {
                    
                    Text("Гадания")
                        .font(.system(size: 34, weight: .bold)) // Размер и вес как у largeTitle
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewSession = true
                    }) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.accentColor]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .accessibility(label: Text("Новое гадание"))
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
                
                // Поиск и фильтры
                VStack(spacing: 12) {
                    SearchBar(text: $searchText, placeholder: "Поиск по клиентам")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterButton(title: "Все", isSelected: filterType == .all) {
                                filterType = .all
                            }
                            
                            FilterButton(title: "Отправлено", isSelected: filterType == .sent) {
                                filterType = .sent
                            }
                            
                            FilterButton(title: "Не отправлено", isSelected: filterType == .notSent) {
                                filterType = .notSent
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollDisabled(true)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                // Список сессий
                if isLoading {
                    Spacer()
                    ProgressView("Загрузка гаданий...")
                    Spacer()
                } else if let error = errorMessage {
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
                } else if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty && filterType == .all {
                            Text("Нет сохраненных гаданий")
                                .font(.headline)
                            
                            Text("Начните новое гадание")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Новое гадание") {
                                showingNewSession = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        } else {
                            Text("Гаданий не найдено")
                                .font(.headline)
                            
                            Text("Попробуйте изменить поиск или фильтры")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSessions) { session in
                                SessionRow(session: session)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        print("Выбрана сессия ID: \(session.id)")
                                        print("Клиент: \(session.clientName)")
                                        print("Расклад: \(session.spreadName)")
                                        selectedSession = session
                                        showSessionDetail = true
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        fetchSessions()
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            ClientInputView()
        }
        .sheet(isPresented: $showSessionDetail) {
            if let session = selectedSession {
                SessionDetailView(session: session)
            } else {
                Text("No session selected") // Для отладки
            }
        }
        .onAppear {
            startListening()
        }
        .onDisappear {
            stopListening()
        }
        .navigationBarHidden(true)
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

// MARK: - Вспомогательные компоненты

/// Строка сессии для списка
struct SessionRow: View {
    let session: TarotSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.clientName), \(session.clientAge!)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                }
                
                Spacer()
                
                // Статус отправки
                if session.isSent {
                    Text("Отправлено")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                } else {
                    Text("Не отправлено")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
            
            // Текст вопроса
            if let questionText = session.questionText, !questionText.isEmpty {
                Text(questionText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            
            // Категория вопроса
            if let category = session.questionCategoryName, !category.isEmpty {
                Text(category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Название расклада
            Text(session.spreadName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(formattedDate(session.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Кнопка "Подробнее"
            HStack {
                Spacer()
                Text("Подробнее →")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Панель поиска
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

/// Кнопка фильтра
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

#Preview {
    SessionsListView()
        .environmentObject(AuthManager())
}
