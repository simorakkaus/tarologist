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
    // FirestoreService будет добавлен позже
    
    @State private var sessions: [TarotSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingNewSession = false
    @State private var searchText = ""
    
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
        VStack(spacing: 0) {
            // Поиск и фильтры
            VStack(spacing: 12) {
                SearchBar(text: $searchText, placeholder: "Поиск по клиентам")
                    .padding(.horizontal)
                
                HStack {
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
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Список сессий
            if isLoading {
                ProgressView("Загрузка гаданий...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredSessions.isEmpty {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredSessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRow(session: session)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteSession(session)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            
                            if !session.isSent {
                                Button {
                                    markAsSent(session)
                                } label: {
                                    Label("Отметить отправленным", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    fetchSessions()
                }
            }
        }
        .navigationTitle("История гаданий")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewSession = true }) {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            ClientInputView()
        }
        .onAppear {
            fetchSessions()
        }
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
        
        TarotSessionManager.shared.fetchSessions(for: userID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sessions):
                    self.sessions = sessions
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Действия с сессиями
    
    private func deleteSession(_ session: TarotSession) {
        guard let userID = authManager.getCurrentUserId() else { return }
        
        TarotSessionManager.shared.deleteSession(session, for: userID) { result in
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
            isSent: true  // Устанавливаем isSent в true
        )
        
        TarotSessionManager.shared.updateSession(updatedSession, for: userID) { result in
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.clientName)
                    .font(.headline)
                
                Spacer()
                
                if session.isSent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                }
            }
            
            Text(session.spreadName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(formattedDate(session.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
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
                .textFieldStyle(PlainTextFieldStyle())
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
                .font(.caption)
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
