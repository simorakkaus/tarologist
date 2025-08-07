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

    @State private var interpretations: [String]
    @State private var clientSummary: String = ""
    @State private var isComplete = false

    init(sessionId: String, cards: [TarotCard]) {
        self.sessionId = sessionId
        self.cards = cards
        _interpretations = State(initialValue: cards.map { $0.meaning })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Редактирование толкования")
                .font(.title2)

            ScrollView {
                ForEach(cards.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cards[index].name)
                            .font(.headline)

                        TextEditor(text: $interpretations[index])
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
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

            NavigationLink(destination: FinalizeReadingView(sessionId: sessionId, summary: clientSummary), isActive: $isComplete) {
                EmptyView()
            }
        }
        .padding()
    }

    /// Сохраняем толкование в Firestore (опционально, можно позже)
    private func saveInterpretation() {
        let db = Firestore.firestore()
        let docRef = db.collection("readings").document(sessionId)

        let interpretationData: [[String: String]] = zip(cards, interpretations).map { card, meaning in
            [
                "name": card.name,
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
