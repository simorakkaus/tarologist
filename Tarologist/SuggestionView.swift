//
//  SuggestionView.swift
//  Tarologist
//
//  Created by Simo on 17.10.2025.
//

// Добавьте этот код в тот же файл или создайте новый файл SuggestionView.swift

import SwiftUI

struct SuggestionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: QuestionCategory?
    @State private var newCategoryName: String = ""
    @State private var questionText: String = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    
    let categories: [QuestionCategory]
    
    var body: some View {
        NavigationView {
            Form {
                    Section(header: Text("Категория")) {
                        Picker("Выберите категорию", selection: $selectedCategory) {
                            Text("Не выбрана").tag(nil as QuestionCategory?)
                            ForEach(categories) { category in
                                Text(category.name).tag(category as QuestionCategory?)
                            }
                        }
                        
                        if selectedCategory == nil {
                            Text("Или введите новую категорию")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Название категории", text: $newCategoryName)
                        }
                    }
                    
                    Section(header: Text("Вопрос")) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $questionText)
                                .frame(minHeight: 100)
                                .padding(.horizontal, -4)
                                .padding(.vertical, -2)
                            
                            if questionText.isEmpty {
                                Text("Введите ваш вопрос")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                
                
                Section {
                    Button(action: submitSuggestion) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Отправить предложение")
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Предложить идею")
            .navigationBarItems(
                leading: Button("Отменить") {
                    dismiss()
                }
            )
            .alert("Спасибо!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Ваше предложение принято! Мы рассмотрим его и добавим в ближайшее время.")
            }
        }
    }
    
    var isFormValid: Bool {
        
            return (!questionText.trimmingCharacters(in: .whitespaces).isEmpty) &&
                   (selectedCategory != nil || !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)

    }
    
    private func submitSuggestion() {
        isLoading = true
        
        // Формируем содержимое письма
        let subject: String
        let body: String
        
        
            let categoryName = selectedCategory?.name ?? newCategoryName
            subject = "Предложение нового вопроса: \(categoryName)"
            body = """
            Тип предложения: Новый вопрос
            Категория: \(categoryName)
            Вопрос: \(questionText)
            
            \(selectedCategory == nil ? "Примечание: Пользователь предложил новую категорию" : "")
            
            ---
            Отправлено из приложения Таролог
            """
        
        
        // Открываем почтовый клиент
        let email = "mailto:funnyzv@gmail.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: email) {
            UIApplication.shared.open(url) { success in
                isLoading = false
                if success {
                    showSuccessAlert = true
                }
            }
        } else {
            isLoading = false
        }
    }
}
