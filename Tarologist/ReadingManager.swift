//
//  ReadingManager.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReadingManager: ObservableObject {
    @Published var interpretation: String = ""
    @Published var isGeneratingInterpretation = false
    
    private let db = Firestore.firestore()
    
    func generateInterpretation(
        for drawnCards: [DrawnCard],
        clientName: String,
        clientAge: String,
        question: String,
        questionCategory: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isGeneratingInterpretation = true
        
        // Создаем промпт для ИИ
        var prompt = "Ты опытный таролог. Проанализируй следующий расклад:\n\n"
        prompt += "Клиент: \(clientName), возраст: \(clientAge)\n"
        prompt += "Категория вопроса: \(questionCategory)\n"
        prompt += "Вопрос: \(question)\n\n"
        prompt += "Расклад:\n"
        
        for drawnCard in drawnCards {
            let position = drawnCard.positionName
            let cardName = drawnCard.card.nameRu
            let orientation = drawnCard.isReversed ? "перевернутая" : "прямая"
            let meaning = drawnCard.isReversed ? drawnCard.card.meaningShadow : drawnCard.card.meaningLight
            
            prompt += "- \(position): \(cardName) (\(orientation)) - \(meaning)\n"
        }
        
        prompt += "\nПредоставь подробное, empathetic толкование на русском языке, которое поможет клиенту понять ситуацию и возможные пути развития."
        
        // Здесь будет интеграция с AIService
        // Временно используем заглушку
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.interpretation = """
            На основе выпавших карт, можно сказать следующее:
            
            В прошлом прослеживается влияние карты \(drawnCards[0].card.nameRu), что указывает на \(drawnCards[0].isReversed ? drawnCards[0].card.meaningShadow : drawnCards[0].card.meaningLight).
            
            В настоящей ситуации \(drawnCards[1].card.nameRu) предполагает \(drawnCards[1].isReversed ? drawnCards[1].card.meaningShadow : drawnCards[1].card.meaningLight).
            
            В будущем возможно развитие в направлении \(drawnCards[2].isReversed ? drawnCards[2].card.meaningShadow : drawnCards[2].card.meaningLight), как указывает карта \(drawnCards[2].card.nameRu).
            
            Общая рекомендация: обратите внимание на свои внутренние ощущения и доверьтесь интуиции при принятии решений.
            """
            
            self.isGeneratingInterpretation = false
            completion(.success(()))
        }
    }
    
    func saveReading(
        clientName: String,
        clientAge: String,
        questionCategory: QuestionCategory,
        question: Question?,
        customQuestion: String?,
        spread: Spread,
        drawnCards: [DrawnCard],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "ReadingManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])))
            return
        }
        
        // Генерируем ID для новой сессии
        let sessionId = UUID().uuidString
        
        // Преобразуем drawnCards в словарь для Firestore
        let drawnCardsData = drawnCards.map { card in
            return [
                "cardId": card.card.id,
                "positionId": card.position.id,
                "positionName": card.position.name,
                "isReversed": card.isReversed
            ]
        }
        
        let readingData: [String: Any] = [
            "id": sessionId,
            "clientName": clientName,
            "clientAge": clientAge,
            "questionCategoryId": questionCategory.id,
            "questionCategoryName": questionCategory.name,
            "questionId": question?.id ?? NSNull(),
            "questionText": question?.text ?? customQuestion ?? NSNull(),
            "spreadId": spread.id,
            "spreadName": spread.name,
            "drawnCards": drawnCardsData,
            "interpretation": interpretation,
            "date": Timestamp(date: Date()),
            "isSent": false
        ]
        
        
        db.collection("users")
            .document(userId)
            .collection("sessions")
            .document(sessionId)     // ← Используем наш сгенерированный ID
            .setData(readingData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
}
