//
//  InterpretationEditorView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseFirestore

/// Экран редактирования толкования расклада
struct InterpretationEditorView: View {
    let sessionId: String
    let cards: [TarotCard]
    let isReversed: [Bool] // Добавляем информацию о положении карт

    @State private var interpretations: [String]
    @State private var clientSummary: String = ""
    @State private var isComplete = false

    init(sessionId: String, cards: [TarotCard], isReversed: [Bool]) {
        self.sessionId = sessionId
        self.cards = cards
        self.isReversed = isReversed
        
        // Используем правильное значение в зависимости от положения карты
        _interpretations = State(initialValue: zip(cards, isReversed).map { card, reversed in
            reversed ? card.meaningShadow : card.meaningLight
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Редактирование толкования")
                .font(.title2)

            ScrollView {
                ForEach(cards.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        // Используем nameRu вместо name
                        Text(cards[index].nameRu)
                            .font(.headline)
                        
                        // Показываем положение карты
                        Text(isReversed[index] ? "Перевернутая" : "Прямая")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $interpretations[index])
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 16)
                }
            }

            Text("Общий текст для клиента:")
                .font(.headline)

            TextEditor(text: $clientSummary)
                .frame(height: 150)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button("Сохранить и продолжить") {
                saveInterpretation()
                isComplete = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()

            NavigationLink(
                destination: FinalizeReadingView(
                    sessionId: sessionId,
                    summary: clientSummary
                ),
                isActive: $isComplete
            ) {
                EmptyView()
            }
        }
        .padding()
    }

    /// Сохраняем толкование в Firestore
    private func saveInterpretation() {
        let db = Firestore.firestore()
        let docRef = db.collection("readings").document(sessionId)

        let interpretationData: [[String: Any]] = zip(zip(cards, interpretations), isReversed).map { item, reversed in
            let (card, meaning) = item
            return [
                "cardId": card.id,
                "nameRu": card.nameRu,
                "nameEn": card.nameEn,
                "isReversed": reversed,
                "meaning": meaning
            ]
        }

        docRef.setData([
            "cards": interpretationData,
            "summary": clientSummary,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
}
