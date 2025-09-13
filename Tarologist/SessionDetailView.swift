//
//  SessionDetailView.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import SwiftUI
import FirebaseFirestore

struct SessionDetailView: View {
    let session: TarotSession
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authManager: AuthManager  // Правильное имя
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingEditView = false
    @State private var isLoading = false
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Заголовок с информацией о клиенте
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.clientName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(formattedDate(session.date))
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "doc.text")
                        Text(session.spreadName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                    
                    if session.isSent {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Отправлено клиенту")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Толкование
                if let interpretation = session.interpretation, !interpretation.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Толкование")
                            .font(.headline)
                        
                        Text(interpretation)
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Толкование отсутствует")
                            .font(.headline)
                        
                        Text("Для этой сессии еще не сгенерировано толкование")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                
                // Кнопки действий
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    if !session.isSent {
                        Button(action: markAsSent) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Отметить отправленным")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    Button(action: { showingShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Поделиться")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: { showingEditView = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Редактировать")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Удалить")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Детали сессии")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .alert("Удалить сессию?", isPresented: $showingDeleteAlert) {
            Button("Удалить", role: .destructive) {
                deleteSession()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы уверены, что хотите удалить эту сессию? Это действие нельзя отменить.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareContent()])
        }
        .sheet(isPresented: $showingEditView) {
            EditSessionView(session: session)
        }
    }
    
    // MARK: - Форматирование даты
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Действия с сессией
    private func markAsSent() {
            guard let userID = authManager.getCurrentUserId() else {
                print("Ошибка: пользователь не авторизован")
                return
            }
            
            isLoading = true
            print("Отметка сессии \(session.id) как отправленной")
            
            Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("sessions")
                .document(session.id)
                .updateData(["isSent": true]) { error in
                    isLoading = false
                    
                    if let error = error {
                        print("Ошибка обновления сессии: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Сессия успешно отмечена как отправленная")
                    // Обновляем локальную сессию и возвращаемся к списку
                    presentationMode.wrappedValue.dismiss()
                }
        }
    
    private func deleteSession() {
            guard let userID = authManager.getCurrentUserId() else {
                print("Ошибка: пользователь не авторизован")
                return
            }
            
            isLoading = true
            print("Удаление сессии \(session.id)")
            
            Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("sessions")
                .document(session.id)
                .delete { error in
                    isLoading = false
                    
                    if let error = error {
                        print("Ошибка удаления сессии: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Сессия успешно удалена")
                    // Возвращаемся к списку после удаления
                    presentationMode.wrappedValue.dismiss()
                }
        }
    
    private func shareContent() -> String {
        var content = "Сессия гадания для \(session.clientName)\n"
        content += "Дата: \(formattedDate(session.date))\n"
        content += "Расклад: \(session.spreadName)\n\n"
        
        if let interpretation = session.interpretation {
            content += "Толкование:\n\(interpretation)"
        } else {
            content += "Толкование отсутствует"
        }
        
        return content
    }
}

// MARK: - Вспомогательные View

/// View для редактирования сессии
struct EditSessionView: View {
    let session: TarotSession
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authManager: AuthManager
    @State private var clientName: String
    @State private var isLoading = false
    
    init(session: TarotSession) {
        self.session = session
        _clientName = State(initialValue: session.clientName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о клиенте")) {
                    TextField("Имя клиента", text: $clientName)
                }
                
                Section {
                    Button("Сохранить изменения") {
                        saveChanges()
                    }
                    .disabled(clientName.isEmpty || isLoading)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let userID = authManager.getCurrentUserId() else { return }
        
        isLoading = true
        
        Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("sessions")
            .document(session.id)
            .updateData(["clientName": clientName]) { error in
                isLoading = false
                
                if let error = error {
                    print("Ошибка обновления сессии: \(error.localizedDescription)")
                    return
                }
                
                presentationMode.wrappedValue.dismiss()
            }
    }
}

/// Обертка для UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Ничего не нужно обновлять
    }
}

#Preview {
    NavigationView {
        SessionDetailView(session: TarotSession(
            id: "1",
            clientName: "Мария",
            date: Date(),
            spreadId: "three-card",
            spreadName: "Расклад на три карты",
            interpretation: "Это пример толкования, которое может быть сгенерировано ИИ для данной сессии гадания. Карты показывают...",
            isSent: false
        ))
        .environmentObject(AuthManager())
    }
}

