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
    let id: String
    let clientName: String
    let clientAge: String?
    let date: Date
    let spreadId: String
    let spreadName: String
    let questionCategoryId: String?
    let questionCategoryName: String?
    let questionText: String?
    let interpretation: String?
    let isSent: Bool
    
    // Добавляем инициализатор для совместимости с Firestore
    init(
        id: String,
        clientName: String,
        clientAge: String? = nil,
        date: Date,
        spreadId: String,
        spreadName: String,
        questionCategoryId: String? = nil,
        questionCategoryName: String? = nil,
        questionText: String? = nil,
        interpretation: String? = nil,
        isSent: Bool = false
    ) {
        self.id = id
        self.clientName = clientName
        self.clientAge = clientAge
        self.date = date
        self.spreadId = spreadId
        self.spreadName = spreadName
        self.questionCategoryId = questionCategoryId
        self.questionCategoryName = questionCategoryName
        self.questionText = questionText
        self.interpretation = interpretation
        self.isSent = isSent
    }
    
    // Добавляем инициализатор из Firestore документа
    // Убедитесь, что у вас есть такой инициализатор в TarotSession
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let id = data["id"] as? String,
              let clientName = data["clientName"] as? String,
              let clientAge = data["clientAge"] as? String,
              let date = data["date"] as? Timestamp,
              let spreadId = data["spreadId"] as? String,
              let spreadName = data["spreadName"] as? String,
              let questionCategoryId = data["questionCategoryId"] as? String,
              let questionCategoryName = data["questionCategoryName"] as? String,
              let interpretation = data["interpretation"] as? String,
              let isSent = data["isSent"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.clientName = clientName
        self.clientAge = clientAge
        self.date = date.dateValue()
        self.spreadId = spreadId
        self.spreadName = spreadName
        self.questionCategoryId = questionCategoryId
        self.questionCategoryName = questionCategoryName
        self.questionText = data["questionText"] as? String
        self.interpretation = interpretation
        self.isSent = isSent
    }
    
    // Преобразование в словарь для Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "clientName": clientName,
            "date": Timestamp(date: date),
            "spreadId": spreadId,
            "spreadName": spreadName,
            "isSent": isSent
        ]
        
        if let clientAge = clientAge {
            dict["clientAge"] = clientAge
        }
        
        if let questionCategoryId = questionCategoryId {
            dict["questionCategoryId"] = questionCategoryId
        }
        
        if let questionCategoryName = questionCategoryName {
            dict["questionCategoryName"] = questionCategoryName
        }
        
        if let questionText = questionText {
            dict["questionText"] = questionText
        }
        
        if let interpretation = interpretation {
            dict["interpretation"] = interpretation
        }
        
        return dict
    }
}

// Расширение для удобства отображения в UI
extension TarotSession {
    /// Краткое описание сессии для отображения в списке
    var shortDescription: String {
        if let questionText = questionText {
            return "\(spreadName) - \(questionText)"
        }
        return spreadName
    }
    
    /// Форматированная дата сессии
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
