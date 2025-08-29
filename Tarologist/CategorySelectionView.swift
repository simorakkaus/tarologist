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
                        Text(category.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Выберите категорию")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
