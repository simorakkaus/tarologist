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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question.text)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if selectedQuestion?.id == question.id {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выберите вопрос")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
