//
//  Spread.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

struct Spread: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let numberOfCards: Int
    let positions: [SpreadPosition]
    let imageName: String?
    let isActive: Bool
}

struct SpreadPosition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let order: Int
}
