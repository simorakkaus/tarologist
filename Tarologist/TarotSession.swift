//
//  TarotSession.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import Foundation
import FirebaseFirestore

/// Модель одной сессии гадания
struct TarotSession: Identifiable, Codable {
    var id: String
    var clientName: String
    var date: Date
    var spreadId: String
    var spreadName: String
    var aiInterpretation: String?
    var isSent: Bool
    
    // Добавляем инициализатор для совместимости с Firestore
    init(id: String, clientName: String, date: Date, spreadId: String, spreadName: String, aiInterpretation: String? = nil, isSent: Bool = false) {
        self.id = id
        self.clientName = clientName
        self.date = date
        self.spreadId = spreadId
        self.spreadName = spreadName
        self.aiInterpretation = aiInterpretation
        self.isSent = isSent
    }
    
    // Добавляем инициализатор из Firestore документа
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let clientName = data["clientName"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let spreadId = data["spreadId"] as? String,
              let spreadName = data["spreadName"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.clientName = clientName
        self.date = timestamp.dateValue()
        self.spreadId = spreadId
        self.spreadName = spreadName
        self.aiInterpretation = data["aiInterpretation"] as? String
        self.isSent = data["isSent"] as? Bool ?? false
    }
    
    // Преобразование в словарь для Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "clientName": clientName,
            "date": Timestamp(date: date),
            "spreadId": spreadId,
            "spreadName": spreadName,
            "isSent": isSent
        ]
        
        if let interpretation = aiInterpretation {
            dict["aiInterpretation"] = interpretation
        }
        
        return dict
    }
}
