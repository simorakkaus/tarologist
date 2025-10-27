//
//  QuestionSelectionView.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import SwiftUI

struct QuestionSelectionView: View {
    let questions: [Question]
    @Binding var selectedQuestion: Question?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(questions) { question in
                Button(action: {
                    selectedQuestion = question
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(question.text)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if selectedQuestion?.id == question.id {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .symbolRenderingMode(.hierarchical)
                            
                        }
                    }
                }
            }
            .navigationTitle("Выберите вопрос")
            .navigationBarItems(leading: Button("Отменить") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
