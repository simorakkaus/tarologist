//
//  SessionsListView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Модель одной сессии гадания
struct TarotSession: Identifiable {
    var id: String
    var clientName: String
    var date: Date
}

/// Экран списка прошлых сессий гадания
struct SessionsListView: View {
    @State private var sessions: [TarotSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text("История гаданий")
                .font(.title2)
                .padding(.top)

            if isLoading {
                ProgressView("Загрузка...")
                    .padding()
            } else if let error = errorMessage {
                Text("Ошибка: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else if sessions.isEmpty {
                Spacer()
                Text("Нет сохранённых гаданий")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Клиент: \(session.clientName)")
                            .font(.headline)
                        Text("Дата: \(formattedDate(session.date))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            NavigationLink(destination: ClientInputView()) {
                Text("Новое гадание")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .padding(.horizontal)
        .onAppear {
            fetchSessions()
        }
    }

    // MARK: - Загрузка сессий из Firestore

    private func fetchSessions() {
        guard let userID = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Пользователь не авторизован"
            self.isLoading = false
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("sessions")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.sessions = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        guard let clientName = data["clientName"] as? String,
                              let timestamp = data["date"] as? Timestamp else {
                            return nil
                        }

                        return TarotSession(
                            id: doc.documentID,
                            clientName: clientName,
                            date: timestamp.dateValue()
                        )
                    } ?? []
                }
            }
    }

    // MARK: - Форматирование даты
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
