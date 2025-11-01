//
//  SpreadSelectionView.swift
//  Tarologist
//
//  Created by Simo on 30.08.2025.
//

import SwiftUI

struct SpreadSelectionView: View {
    let clientName: String
    let clientAge: String
    let questionCategory: QuestionCategory
    let question: Question?
    let customQuestion: String?
    
    @StateObject private var spreadManager = SpreadManager()
    @State private var selectedSpread: Spread?
    @State private var navigateToReading = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                if spreadManager.isLoading {
                    LoadingScreenView()
                } else if let error = spreadManager.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Ошибка загрузки")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Повторить") {
                            spreadManager.loadSpreads()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(spreadManager.spreads) { spread in
                        Button(action: {
                            selectedSpread = spread
                        }) {
                            SpreadRow(spread: spread, isSelected: selectedSpread?.id == spread.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Выбор расклада")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Назад") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Далее") {
                        navigateToReading = true
                    }
                    .disabled(selectedSpread == nil)
                }
            }
            .background(
                NavigationLink(
                    destination: selectedSpread.map { spread in
                        CardReadingView(
                            clientName: clientName,
                            clientAge: clientAge,
                            questionCategory: questionCategory,
                            question: question,
                            customQuestion: customQuestion,
                            selectedSpread: spread
                        )
                    },
                    isActive: $navigateToReading,
                    label: { EmptyView() }
                )
            )
            .onAppear {
                spreadManager.loadSpreads()
            }
        }
        
    }
}
