//
//  CategorySelectionView.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import SwiftUI

struct CategorySelectionView: View {
    let categories: [QuestionCategory]
    @Binding var selectedCategory: QuestionCategory?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(categories) { category in
                Button(action: {
                    selectedCategory = category
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .foregroundColor(.primary)
                            Text(category.description ?? "")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        if selectedCategory?.id == category.id {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            }
            .navigationTitle("Выберите категорию")
            .navigationBarItems(leading: Button("Отменить") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
