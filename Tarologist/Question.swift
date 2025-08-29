//
//  Question.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import Foundation
import FirebaseFirestore

struct Question: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var categoryId: String
    var text: String
    var isApproved: Bool
    var isActive: Bool
    var createdAt: Date
    
    init(id: String, categoryId: String, text: String, isApproved: Bool = false, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.categoryId = categoryId
        self.text = text
        self.isApproved = isApproved
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let categoryId = data["categoryId"] as? String,
              let text = data["text"] as? String,
              let isApproved = data["isApproved"] as? Bool,
              let isActive = data["isActive"] as? Bool,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.categoryId = categoryId
        self.text = text
        self.isApproved = isApproved
        self.isActive = isActive
        self.createdAt = timestamp.dateValue()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "categoryId": categoryId,
            "text": text,
            "isApproved": isApproved,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
