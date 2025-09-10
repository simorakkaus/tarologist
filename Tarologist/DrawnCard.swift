//
//  DrawnCard.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import Foundation

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
    let position: SpreadPosition
    let isReversed: Bool
    
    var positionName: String {
        return position.name
    }
    
    var positionDescription: String {
        return position.description
    }
}
