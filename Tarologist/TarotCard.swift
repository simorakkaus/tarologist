//
//  TarotCard.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import Foundation

/// Модель карты Таро
struct TarotCard: Identifiable, Codable {
    let id: String
    let name: String
    let meaning: String
    let imageName: String
}
