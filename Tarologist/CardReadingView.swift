//
//  CardReadingView.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import SwiftUI

struct CardReadingView: View {
    let clientName: String
    let clientAge: String
    let questionCategory: QuestionCategory
    let question: Question?
    let customQuestion: String?
    let selectedSpread: Spread
    
    //@StateObject private var aiService = AIService()
    @ObservedObject private var sessionManager = SessionManager.shared
    
    @State private var drawnCards: [DrawnCard] = []
    @State private var currentPositionIndex = 0
    @State private var isDrawingCards = false
    @State private var isInterpretationGenerated = false
    @State private var showInterpretation = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                if isDrawingCards {
                    // Экран процесса вытягивания карт
                    DrawingInProgressView(
                        currentPosition: selectedSpread.positions[currentPositionIndex],
                        progress: Double(currentPositionIndex) / Double(selectedSpread.positions.count)
                    )
                } else if drawnCards.isEmpty {
                    // Экран перед началом гадания
                    PreparationView(
                        clientName: clientName,
                        spreadName: selectedSpread.name,
                        onStartDrawing: startCardDrawing
                    )
                } else {
                    // Основной экран с результатами гадания
                    ScrollView {
                        VStack(spacing: 20) {
                            // Заголовок
                            Text("Расклад: \(selectedSpread.name)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // Сетка с картами
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                ForEach(drawnCards) { drawnCard in
                                    CardView(drawnCard: drawnCard)
                                }
                            }
                            
                            // Кнопка генерации толкования
                            if !isInterpretationGenerated {
                                Button(action: generateInterpretation) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("Сгенерировать толкование")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .padding(.top)
                            }
                            
                            // Результаты толкования
                            if isInterpretationGenerated {
                                InterpretationView(
                                    interpretation: sessionManager.interpretation,
                                    onShowDetails: { showInterpretation = true }
                                )
                            }
                            
                            // Действия с результатами
                            if isInterpretationGenerated {
                                ActionsView(
                                    onSave: saveReading,
                                    onShare: shareReading,
                                    onNewReading: { presentationMode.wrappedValue.dismiss() }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                // Индикатор загрузки для генерации толкования
                if sessionManager.isGeneratingInterpretation {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView("Генерация толкования...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Гадание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Назад") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showInterpretation) {
                InterpretationDetailView(
                    interpretation: sessionManager.interpretation,
                    drawnCards: drawnCards
                )
            }
            .alert("Ошибка", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Card Drawing
    
    private func startCardDrawing() {
        isDrawingCards = true
        drawnCards = []
        currentPositionIndex = 0
        
        // Анимированное вытягивание карт по одной
        let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            drawNextCard()
            
            if currentPositionIndex >= selectedSpread.positions.count {
                timer.invalidate()
                isDrawingCards = false
            }
        }
        
        timer.fire()
    }
    
    private func drawNextCard() {
        guard currentPositionIndex < selectedSpread.positions.count else { return }
        
        let position = selectedSpread.positions[currentPositionIndex]
        let randomCard = TarotCardManager.shared.cards.randomElement()!
        let isReversed = Bool.random()
        
        let drawnCard = DrawnCard(
            card: randomCard,
            position: position,
            isReversed: isReversed
        )
        
        drawnCards.append(drawnCard)
        currentPositionIndex += 1
    }
    
    // MARK: - Interpretation
    
    private func generateInterpretation() {
            sessionManager.generateInterpretation(
                for: drawnCards,
                clientName: clientName,
                clientAge: clientAge,
                question: question?.text ?? customQuestion ?? "",
                questionCategory: questionCategory.name
            ) { result in
                switch result {
            case .success:
                isInterpretationGenerated = true
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Save & Share
    
    private func saveReading() {
            sessionManager.saveReading(
                clientName: clientName,
                clientAge: clientAge,
                questionCategory: questionCategory,
                question: question,
                customQuestion: customQuestion,
                spread: selectedSpread,
                drawnCards: drawnCards,
                interpretation: sessionManager.interpretation  // Добавьте этот параметр
            ) { result in
            switch result {
            case .success:
                print("Расклад сохранен")
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func shareReading() {
        // Реализация分享功能
        print("分享功能")
    }
}

// MARK: - Supporting Views

struct PreparationView: View {
    let clientName: String
    let spreadName: String
    let onStartDrawing: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cards")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Готовы к гаданию?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Для \(clientName)")
                .font(.headline)
            
            Text("Расклад: \(spreadName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Начать гадание", action: onStartDrawing)
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)
        }
        .padding()
        .multilineTextAlignment(.center)
    }
}

struct DrawingInProgressView: View {
    let currentPosition: SpreadPosition
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .padding(.horizontal)
            
            Text("Вытягиваю карту...")
                .font(.headline)
            
            Text("Позиция: \(currentPosition.name)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(currentPosition.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Image(systemName: "hand.draw")
                .font(.system(size: 40))
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct CardView: View {
    let drawnCard: DrawnCard
    
    var body: some View {
        VStack(spacing: 8) {
            // Заглушка для изображения карты
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                
                VStack {
                    Text(drawnCard.isReversed ? "↻" : "↑")
                        .font(.caption)
                    
                    Text(drawnCard.card.nameRu)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text(drawnCard.positionName)
                .font(.caption)
                .fontWeight(.bold)
            
            Text(drawnCard.positionDescription)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

struct InterpretationView: View {
    let interpretation: String
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Толкование")
                    .font(.headline)
                
                Spacer()
                
                Button("Подробнее", action: onShowDetails)
                    .font(.caption)
            }
            
            Text(interpretation.prefix(200) + (interpretation.count > 200 ? "..." : ""))
                .font(.body)
                .lineLimit(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActionsView: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let onNewReading: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Сохранить расклад", action: onSave)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            
            Button("Поделиться", action: onShare)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            
            Button("Новое гадание", action: onNewReading)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

#Preview {
    CardReadingView(
        clientName: "Мария",
        clientAge: "30",
        questionCategory: QuestionCategory(
            id: "love",
            name: "Любовь и отношения",
            description: "Вопросы о любовных отношениях"
        ),
        question: Question(
            id: "love_future",
            categoryId: "love",
            text: "Что меня ждет в любви?",
            isApproved: true,
            isActive: true,
            createdAt: Date()
        ),
        customQuestion: nil,
        selectedSpread: Spread(
            id: "three_card",
            name: "Расклад на три карты",
            description: "Простой расклад для понимания прошлого, настоящего и будущего ситуации",
            numberOfCards: 3,
            positions: [
                SpreadPosition(id: "past", name: "Прошлое", description: "Влияние прошлого на текущую ситуацию", order: 1),
                SpreadPosition(id: "present", name: "Настоящее", description: "Текущее состояние ситуации", order: 2),
                SpreadPosition(id: "future", name: "Будущее", description: "Возможное развитие событий", order: 3)
            ],
            imageName: "three_card_spread"
        )
    )
}
