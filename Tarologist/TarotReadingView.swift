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
    @State private var isReversed: [Bool] = [] // Добавляем массив для положений карт
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
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // Используем imageName из структуры TarotCard
                            Image(card.imageName)
                                .resizable()
                                .frame(width: 80, height: 130)
                                .cornerRadius(8)
                                .shadow(radius: 4)

                            VStack(alignment: .leading) {
                                Text(card.nameRu) // Используем русское название
                                    .font(.headline)
                                
                                // Показываем положение карты
                                Text(isReversed[index] ? "Перевернутая" : "Прямая")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Используем соответствующее значение в зависимости от положения
                                Text(isReversed[index] ? card.meaningShadow : card.meaningLight)
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

            NavigationLink(
                destination: InterpretationEditorView(
                    sessionId: sessionId,
                    cards: cards,
                    isReversed: isReversed // Передаем массив положений карт
                ),
                isActive: $isReadyToInterpret
            ) {
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

    /// Генерируем случайный расклад из карт
    private func generateCards() {
        // Получаем все карты из менеджера
        let allCards = TarotCardManager.shared.cards
        
        // Выбираем случайные карты (например, 3 карты)
        cards = Array(allCards.shuffled().prefix(3))
        
        // Генерируем случайные положения для каждой карты
        isReversed = cards.map { _ in Bool.random() }
    }
}
