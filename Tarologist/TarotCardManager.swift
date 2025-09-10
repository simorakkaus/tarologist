//
//  TarotCardManager.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import Foundation

class TarotCardManager {
    static let shared = TarotCardManager()
    private(set) var cards: [TarotCard] = []
    
    private init() {
        loadCards()
    }
    
    private func loadCards() {
        // Загрузка из локального JSON файла
        guard let url = Bundle.main.url(forResource: "tarot_cards", withExtension: "json") else {
            print("Не найден файл tarot_cards.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            cards = try decoder.decode([TarotCard].self, from: data)
            print("Загружено \(cards.count) карт")
        } catch {
            print("Ошибка загрузки карт: \(error)")
        }
    }
    
    func card(byId id: String) -> TarotCard? {
        return cards.first { $0.id == id }
    }
    
    func card(byEnglishName name: String) -> TarotCard? {
        return cards.first { $0.nameEn.lowercased() == name.lowercased() }
    }
}
