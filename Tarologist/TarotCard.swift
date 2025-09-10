//
//  TarotCard.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import Foundation

struct TarotCard: Identifiable, Codable, Hashable {
    /// Уникальный идентификатор карты (например: "fool", "magician", "ace_of_wands")
    /// Используется для однозначной идентификации карты в системе
    let id: String
    
    /// Название карты на английском языке (например: "The Fool", "The Magician")
    /// Используется для поиска файла изображения карты в бандле приложения
    let nameEn: String
    
    /// Название карты на русском языке (например: "Шут", "Маг")
    /// Используется для отображения пользователю в интерфейсе приложения
    let nameRu: String
    
    /// Имя файла изображения карты в бандле приложения (например: "fool", "magician")
    /// Должно соответствовать имени файла в assets без расширения
    let imageName: String
    
    /// Краткое описание карты, ее основная тематика и символика
    /// Используется для быстрого ознакомления с картой
    let description: String
    
    /// Значение карты в прямом положении (позитивное толкование)
    /// Описывает благоприятные аспекты и возможности карты
    let meaningLight: String
    
    /// Значение карты в перевернутом положении (проблемное толкование)
    /// Описывает сложности, предупреждения и вызовы карты
    let meaningShadow: String
    
    /// Флаг, указывающий является ли карта Старшим Арканом
    /// true - Старший Аркан, false - Младший Аркан
    let isMajor: Bool
    
    /// Масть карты для Младших Арканов (например: "wands", "cups", "swords", "pentacles")
    /// Для Старших Арканов имеет значение nil
    let suit: String?
    
    // Для соответствия Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TarotCard, rhs: TarotCard) -> Bool {
        return lhs.id == rhs.id
    }
}
