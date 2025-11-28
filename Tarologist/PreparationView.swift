//
//  PreparationView.swift
//  Tarologist
//
//  Created by Simo on 28.11.2025.
//

import SwiftUI

struct PreparationView: View {
    let clientName: String
    let clientAge: String
    let spreadName: String
    let spreadDescription: String  // ← добавить
    let numberOfCards: Int         // ← добавить
    let questionCategory: String
    let questionText: String
    let onStartDrawing: () -> Void
    
    @State private var symbolAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Большой анимированный SF Symbol
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.breathe.pulse.byLayer, options: .repeat(.periodic(delay: 6.0)))
            
            // Основной поясняющий текст
            Text("Настройтесь на энергию Таро во благо вопрошающего")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Персонализированный текст
            VStack(spacing: 12) {
                Text("\(clientName), \(clientAge)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Категория вопроса
                Text(questionCategory)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                
                // Текст вопроса
                Text("«\(questionText)»")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                
                Text(spreadName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Кнопка CTA
            Button(action: onStartDrawing) {
                VStack(spacing: 12) {
                    Image(systemName: "hands.and.sparkles")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.blue)
                        .symbolEffect(.wiggle.byLayer, options: .repeat(.periodic(delay: 2.0)))
                    
                    Text("Начать гадание")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 32)
            }
            .padding(.top, 20)
        }
        .padding(32)
        .multilineTextAlignment(.center)
        .onAppear {
            symbolAnimation = true
        }
    }
}
