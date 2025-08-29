//
//  QuestionCategory.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import Foundation
import FirebaseFirestore

struct QuestionCategory: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var description: String?
    var isActive: Bool
    
    init(id: String, name: String, description: String? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.isActive = isActive
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let name = data["name"] as? String,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.description = data["description"] as? String
        self.isActive = isActive
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "isActive": isActive
        ]
        
        if let description = description {
            dict["description"] = description
        }
        
        return dict
    }
    
    static func == (lhs: QuestionCategory, rhs: QuestionCategory) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
