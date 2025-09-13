//
//  SessionManager.swift
//  Tarologist
//
//  Created by Simo on 10.09.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class SessionManager: ObservableObject {
    @Published var interpretation: String = ""
    @Published var isGeneratingInterpretation = false
    
    private let db = Firestore.firestore()
    static let shared = SessionManager()
    
    private init() {}
    
    // MARK: - Session Management
    
    func saveSession(_ session: TarotSession, for userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Используем ID сессии как идентификатор документа
            let ref = db.collection("users")
                .document(userId)
                .collection("sessions")
                .document(session.id)  // Используем существующий ID
            
            let data = try session.toDictionary()
            
            ref.setData(data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(ref.documentID))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchSessions(for userId: String, completion: @escaping (Result<[TarotSession], Error>) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("sessions")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let sessions = snapshot?.documents.compactMap { TarotSession(document: $0) } ?? []
                completion(.success(sessions))
            }
    }
    
    func updateSession(_ session: TarotSession, for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let data = session.toDictionary()
            
            db.collection("users")
                .document(userId)
                .collection("sessions")
                .document(session.id)
                .setData(data) { error in  // Убрали merge: true для полной замены
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        } catch {
            completion(.failure(error))
        }
    }
    
    func startSessionsListener(for userId: String, completion: @escaping (Result<[TarotSession], Error>) -> Void) -> ListenerRegistration {
        return db.collection("users")
            .document(userId)
            .collection("sessions")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Ошибка слушателя сессий: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("Снимок слушателя сессий пуст")
                    completion(.success([]))
                    return
                }
                
                print("Получено \(snapshot.documents.count) сессий через слушатель")
                let sessions = snapshot.documents.compactMap { TarotSession(document: $0) }
                print("Успешно инициализировано \(sessions.count) сессий")
                completion(.success(sessions))
            }
    }
    
    func deleteSession(_ session: TarotSession, for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("sessions")
            .document(session.id)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Reading Operations
    
    // УЛУЧШЕННАЯ ВЕРСИЯ - возвращает интерпретацию в completion
    func generateInterpretation(
        for drawnCards: [DrawnCard],
        clientName: String,
        clientAge: String,
        question: String,
        questionCategory: String,
        completion: @escaping (Result<String, Error>) -> Void
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
            let interpretation = """
            На основе выпавших карт, можно сказать следующее:
            
            В прошлом прослеживается влияние карты \(drawnCards[0].card.nameRu), что указывает на \(drawnCards[0].isReversed ? drawnCards[0].card.meaningShadow : drawnCards[0].card.meaningLight).
            
            В настоящей ситуации \(drawnCards[1].card.nameRu) предполагает \(drawnCards[1].isReversed ? drawnCards[1].card.meaningShadow : drawnCards[1].card.meaningLight).
            
            В будущем возможно развитие в направлении \(drawnCards[2].isReversed ? drawnCards[2].card.meaningShadow : drawnCards[2].card.meaningLight), как указывает карта \(drawnCards[2].card.nameRu).
            
            Общая рекомендация: обратите внимание на свои внутренние ощущения и доверьтесь интуиции при принятии решений.
            """
            
            self.interpretation = interpretation
            self.isGeneratingInterpretation = false
            completion(.success(interpretation))
        }
    }
    
    // УЛУЧШЕННАЯ ВЕРСИЯ - принимает интерпретацию как параметр
    func saveReading(
        clientName: String,
        clientAge: String,
        questionCategory: QuestionCategory,
        question: Question?,
        customQuestion: String?,
        spread: Spread,
        drawnCards: [DrawnCard],
        interpretation: String, // Явный параметр вместо использования свойства
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "SessionManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])))
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
            "interpretation": interpretation, // Используем переданный параметр
            "date": Timestamp(date: Date()),
            "isSent": false
        ]
        
        db.collection("users")
            .document(userId)
            .collection("sessions")
            .document(sessionId)
            .setData(readingData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    
}
