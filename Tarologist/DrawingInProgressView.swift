//
//  DrawingInProgressView.swift
//  Tarologist
//
//  Created by Simo on 30.11.2025.
//

import SwiftUI

struct DrawingInProgressView: View {
    let currentPosition: SpreadPosition
    let spreadName: String
    
    // Настройки анимации
    private let animationDuration: Double = 16.0
    private let symbolSize: Double = 80
    private let accentColor: Color = .blue
    private let secondaryColor: Color = .purple
    
    @State private var symbolAnimation = false
    @State private var progressAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Большой анимированный SF Symbol
            Image(systemName: "eyebrow")
                .font(.system(size: symbolSize))
                .foregroundColor(accentColor)
                .symbolEffect(.breathe.pulse.byLayer, options: .repeating, value: symbolAnimation)
            
            // Основной поясняющий текст
            Text("Вытягиваю карты...")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Дополнительная информация
            VStack(spacing: 12) {
                Text("Позиция: \(currentPosition.name)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(currentPosition.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Подготавливаю расклад: \(spreadName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // ВЫБЕРИ ОДИН ИЗ ВАРИАНТОВ НИЖЕ (раскомментируй нужный):
            
            // 🔮 Вариант 1: Анимированная колода карт
            //animatedDeckView
            
            // 🖐️ Вариант 2: Рука, вытягивающая карты
            // handDrawingView
            
            // 🎴 Вариант 3: Перемешивающиеся карты
            // shufflingCardsView
            
            // ✨ Вариант 4: Магический процесс
             magicalProcessView
            
            // ● Вариант 5: Простой и элегантный
            // elegantDotsView
        }
        .padding(32)
        .multilineTextAlignment(.center)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        symbolAnimation = true
        progressAnimation = true
    }
    
    // MARK: - Варианты анимаций
    
    // 🔮 Вариант 1: Анимированная колода карт
    private var animatedDeckView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "rectangle")
                        .font(.title3)
                        .foregroundColor(accentColor)
                        .symbolEffect(.bounce, value: progressAnimation)
                }
            }
            
            Text("Тасуем карты...")
                .font(.headline)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 20)
    }
    
    // 🖐️ Вариант 2: Рука, вытягивающая карты
    private var handDrawingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.point.up.left")
                .font(.system(size: 44))
                .foregroundColor(accentColor)
                .symbolEffect(.variableColor.iterative, options: .repeating, value: progressAnimation)
            
            Text("Карта появляется...")
                .font(.headline)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 20)
    }
    
    // 🎴 Вариант 3: Перемешивающиеся карты
    private var shufflingCardsView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "rectangle.stack")
                    .font(.title2)
                    .foregroundColor(accentColor)
                    .symbolEffect(.bounce, options: .repeating, value: progressAnimation)
                
                Text("→")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Image(systemName: "rectangle")
                    .font(.title2)
                    .foregroundColor(accentColor)
                    .symbolEffect(.bounce, options: .repeating, value: progressAnimation)
            }
            
            Text("Перемешиваю карты...")
                .font(.headline)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 20)
    }
    
    // ✨ Вариант 4: Магический процесс
    private var magicalProcessView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(accentColor)
                    .symbolEffect(.bounce, value: progressAnimation)
                
                Image(systemName: "wave.3.forward")
                    .font(.title3)
                    .foregroundColor(secondaryColor)
                    .symbolEffect(.variableColor, options: .repeating, value: progressAnimation)
                
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(accentColor)
                    .symbolEffect(.bounce, value: progressAnimation)
            }
            
            Text("Призываю энергию карт...")
                .font(.headline)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 20)
    }
    
    // ● Вариант 5: Простой и элегантный
    private var elegantDotsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(accentColor)
                        .frame(width: 12, height: 12)
                        .opacity(getDotOpacity(for: index))
                        .scaleEffect(getDotScale(for: index))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                    progressAnimation.toggle()
                }
            }
            
            Text("Подключаюсь к картам...")
                .font(.headline)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 20)
    }
    
    // Вспомогательные функции для варианта 5
    private func getDotOpacity(for index: Int) -> Double {
        let baseDelay = Double(index) * 0.3
        let cycleTime = 1.5
        let progress = (Date().timeIntervalSince1970.truncatingRemainder(dividingBy: cycleTime) + baseDelay).truncatingRemainder(dividingBy: cycleTime)
        return progress < 0.5 ? 1.0 : 0.3
    }
    
    private func getDotScale(for index: Int) -> Double {
        let baseDelay = Double(index) * 0.3
        let cycleTime = 1.5
        let progress = (Date().timeIntervalSince1970.truncatingRemainder(dividingBy: cycleTime) + baseDelay).truncatingRemainder(dividingBy: cycleTime)
        return progress < 0.5 ? 1.2 : 0.8
    }
}
