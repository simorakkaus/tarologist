//
//  SpreadSelectionSheetView.swift
//  Tarologist
//
//  Created by Simo on 31.10.2025.
//

import SwiftUI

struct SpreadSelectionSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var spreadManager: SpreadManager
    @Binding var selectedSpread: Spread?
    
    var body: some View {
        NavigationView {
            ZStack {
                if spreadManager.isLoading {
                    ProgressView("Загрузка раскладов...")
                        .scaleEffect(1.5)
                } else if let error = spreadManager.errorMessage {
                    ErrorView.sessionsLoadingError(
                        onRetry: {
                            spreadManager.loadSpreads()
                        }
                    )
                } else {
                    List(spreadManager.spreads) { spread in
                        Button(action: {
                            selectedSpread = spread
                            dismiss()
                        }) {
                            SpreadRow(spread: spread, isSelected: selectedSpread?.id == spread.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                }
            }
            .navigationTitle("Выбор расклада")
            .navigationBarItems(
                leading: Button("Отмена") {
                    dismiss()
                }
            )
        }
    }
}

// Вынесем SpreadRow в отдельную структуру для переиспользования
struct SpreadRow: View {
    let spread: Spread
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(spread.name)
                    .font(.headline)
                
                Text(spread.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Карт: \(spread.numberOfCards)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}


