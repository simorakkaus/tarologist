//
//  TarotSessionManager.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import Foundation
import FirebaseFirestore

class TarotSessionManager {
    static let shared = TarotSessionManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func saveSession(_ session: TarotSession, for userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Сначала создаем ссылку на документ
            let ref = db.collection("users")
                .document(userId)
                .collection("sessions")
                .document() // Создаем новый документ с автоматическим ID
            
            // Преобразуем сессию в словарь
            let data = try session.toDictionary()
            
            // Устанавливаем данные документа
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
            .collection("sessions")  // ← Убедитесь, что это "sessions"
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
                .setData(data, merge: true) { error in
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
}
