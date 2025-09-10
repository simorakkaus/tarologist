//
//  Spread.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import Foundation

struct Spread: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let numberOfCards: Int
    let positions: [SpreadPosition]
    let imageName: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Spread, rhs: Spread) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SpreadPosition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let order: Int
}
