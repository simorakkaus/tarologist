//
//  ClientInputView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Экран ввода информации о клиенте перед началом гадания
struct ClientInputView: View {
    @State private var clientName: String = ""
    @State private var question: String = ""
    @State private var isNavigating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Новое гадание")
                .font(.title)
                .padding(.top)

            TextField("Имя клиента", text: $clientName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Вопрос (необязательно)", text: $question)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            NavigationLink(destination: TarotReadingView(sessionId: UUID().uuidString, clientName: clientName, question: question), isActive: $isNavigating) {
                EmptyView()
            }

            Button("Продолжить") {
                createSession()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 10)

            Spacer()
        }
        .padding()
    }

    /// Создание новой сессии гадания в Firestore
    private func createSession() {
        guard !clientName.isEmpty else {
            errorMessage = "Пожалуйста, введите имя клиента."
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Ошибка: пользователь не авторизован."
            return
        }

        let sessionId = UUID().uuidString

        let sessionData: [String: Any] = [
            "clientName": clientName,
            "question": question,
            "createdAt": Timestamp(date: Date()),
            "userId": userId
        ]

        Firestore.firestore()
            .collection("sessions")
            .document(sessionId)
            .setData(sessionData) { error in
                if let error = error {
                    errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
                } else {
                    errorMessage = nil
                    isNavigating = true
                }
            }
    }
}
