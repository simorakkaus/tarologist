//
//  SpreadManager.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import Foundation
import FirebaseFirestore

class SpreadManager: ObservableObject {
    @Published var spreads: [Spread] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func loadSpreads() {
        isLoading = true
        errorMessage = nil
        
        // Сначала пытаемся загрузить из Firestore
        db.collection("spreads")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Ошибка загрузки раскладов: \(error.localizedDescription)")
                    // Загружаем локальные расклады при ошибке
                    self.loadLocalSpreads()
                    return
                }
                
                let firestoreSpreads = snapshot?.documents.compactMap { document -> Spread? in
                    let data = document.data()
                    return self.parseSpread(from: data, id: document.documentID)
                } ?? []
                
                if firestoreSpreads.isEmpty {
                    self.loadLocalSpreads()
                } else {
                    self.spreads = firestoreSpreads
                    self.saveSpreadsToCache(firestoreSpreads)
                }
                
                self.isLoading = false
            }
    }
    
    private func parseSpread(from data: [String: Any], id: String) -> Spread? {
        guard let name = data["name"] as? String,
              let description = data["description"] as? String,
              let numberOfCards = data["numberOfCards"] as? Int,
              let positionsData = data["positions"] as? [[String: Any]] else {
            return nil
        }
        
        let positions = positionsData.compactMap { positionData -> SpreadPosition? in
            guard let positionId = positionData["id"] as? String,
                  let positionName = positionData["name"] as? String,
                  let positionDescription = positionData["description"] as? String,
                  let order = positionData["order"] as? Int else {
                return nil
            }
            
            return SpreadPosition(
                id: positionId,
                name: positionName,
                description: positionDescription,
                order: order
            )
        }.sorted(by: { $0.order < $1.order })
        
        let imageName = data["imageName"] as? String
        let isActive = data["isActive"] as? Bool ?? true // По умолчанию true

        return Spread(
            id: id, // Используем documentID из Firebase как id
            name: name,
            description: description,
            numberOfCards: numberOfCards,
            positions: positions,
            imageName: imageName,
            isActive: isActive
        )
    }
    
    private func loadLocalSpreads() {
        // Загрузка локальных раскладов из JSON
        guard let url = Bundle.main.url(forResource: "default_spreads", withExtension: "json") else {
            self.errorMessage = "Не удалось загрузить расклады"
            self.isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let localSpreads = try decoder.decode([Spread].self, from: data)
            self.spreads = localSpreads
        } catch {
            self.errorMessage = "Ошибка загрузки локальных раскладов: \(error.localizedDescription)"
        }
        
        self.isLoading = false
    }
    
    private func saveSpreadsToCache(_ spreads: [Spread]) {
        if let encoded = try? JSONEncoder().encode(spreads) {
            UserDefaults.standard.set(encoded, forKey: "cachedSpreads")
        }
    }
    
    private func loadSpreadsFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedSpreads"),
           let spreads = try? JSONDecoder().decode([Spread].self, from: data) {
            self.spreads = spreads
        }
    }
}
