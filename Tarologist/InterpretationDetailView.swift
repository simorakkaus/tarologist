//
//  InterpretationDetailView.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import SwiftUI

struct InterpretationDetailView: View {
    let interpretation: String
    let drawnCards: [DrawnCard]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Полное толкование")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(interpretation)
                        .font(.body)
                        .lineSpacing(6)
                    
                    Divider()
                    
                    Text("Карты в раскладе:")
                        .font(.headline)
                    
                    ForEach(drawnCards) { card in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(card.positionName): \(card.card.nameRu) (\(card.isReversed ? "Перевернутая" : "Прямая"))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(card.isReversed ? card.card.meaningShadow : card.card.meaningLight)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Детали толкования")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
