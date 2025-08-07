//
//  TarotReadingView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseFirestore

/// Экран генерации и отображения расклада Таро
struct TarotReadingView: View {
    let sessionId: String
    let clientName: String
    let question: String

    @State private var cards: [TarotCard] = []
    @State private var isReadyToInterpret = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Расклад для \(clientName)")
                .font(.title2)

            if !question.isEmpty {
                Text("Вопрос: \(question)")
                    .italic()
            }

            ScrollView {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(card.imageName)
                                .resizable()
                                .frame(width: 80, height: 130)
                                .cornerRadius(8)
                                .shadow(radius: 4)

                            VStack(alignment: .leading) {
                                Text(card.name)
                                    .font(.headline)
                                Text(card.meaning)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }

                        Divider()
                    }
                    .padding(.vertical, 8)
                }
            }

            NavigationLink(destination: InterpretationEditorView(sessionId: sessionId, cards: cards), isActive: $isReadyToInterpret) {
                EmptyView()
            }

            Button("Редактировать толкование") {
                isReadyToInterpret = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .onAppear(perform: generateCards)
    }

    /// Временно генерируем случайный расклад из 3 карт
    private func generateCards() {
        // Здесь можно заменить на настоящую генерацию
        cards = [
            TarotCard(id: UUID().uuidString, name: "Шут", meaning: "Новые начинания, свобода", imageName: "fool"),
            TarotCard(id: UUID().uuidString, name: "Влюблённые", meaning: "Выбор, отношения", imageName: "lovers"),
            TarotCard(id: UUID().uuidString, name: "Сила", meaning: "Сила духа, внутренняя уверенность", imageName: "strength")
        ]
    }
}
