//
//  ClientInputView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseFirestore

// Добавляем enum для управления модальными окнами
enum ActiveSheet: Identifiable {
    case categorySelection
    case questionSelection
    
    var id: Int {
        hashValue
    }
}

struct ClientInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var clientName: String = ""
    @State private var clientAge: String = ""
    @State private var selectedCategory: QuestionCategory?
    @State private var selectedQuestion: Question?
    @State private var customQuestion: String = ""
    @State private var isUsingCustomQuestion: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSupportAlert: Bool = false
    @State private var activeSheet: ActiveSheet? // Управление модальными окнами
    
    @StateObject private var questionManager = QuestionManager()
    
    var body: some View {
        NavigationView {
            Form {
                // Section 1: Client Information
                Section(header: Text("Данные клиента")) {
                    TextField("Имя клиента", text: $clientName)
                    TextField("Возраст клиента", text: $clientAge)
                        .keyboardType(.numberPad)
                }
                
                // Section 2: Question Category
                Section(header: Text("Категория вопроса")) {
                    if let selectedCategory = selectedCategory {
                        HStack {
                            Text(selectedCategory.name)
                                .lineLimit(2)
                            Spacer()
                            Button("Изменить") {
                                activeSheet = .categorySelection
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("Выберите категорию вопроса") {
                            activeSheet = .categorySelection
                        }
                    }
                }
                
                // Section 3: Question Selection
                if selectedCategory != nil {
                    Section(header: Text("Вопрос")) {
                        if !isUsingCustomQuestion {
                            if let selectedQuestion = selectedQuestion {
                                HStack {
                                    Text(selectedQuestion.text)
                                        .lineLimit(3)
                                    Spacer()
                                    Button("Изменить") {
                                        activeSheet = .questionSelection
                                    }
                                    .foregroundColor(.blue)
                                }
                            } else {
                                Button("Выберите вопрос") {
                                    activeSheet = .questionSelection
                                }
                            }
                            
                            Button("Не нашли подходящий вопрос?") {
                                isUsingCustomQuestion = true
                            }
                            .foregroundColor(.blue)
                        } else {
                            TextField("Введите свой вопрос", text: $customQuestion)
                                .lineLimit(3)
                            
                            Button("Вернуться к списку вопросов") {
                                isUsingCustomQuestion = false
                                customQuestion = ""
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // Section 4: Support Information
                Section(header: Text("Поддержка")) {
                    Button("Предложить новую категорию или вопрос") {
                        showSupportAlert = true
                    }
                }
            }
            .navigationTitle("Новое гадание")
            .navigationBarItems(
                leading: Button("Отмена") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Начать") {
                    startReading()
                }
                .disabled(!isFormValid)
            )
            .alert("Поддержка", isPresented: $showSupportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Если вы хотите предложить новую категорию или вопрос, пожалуйста, свяжитесь с поддержкой через раздел 'Профиль'.")
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .categorySelection:
                    CategorySelectionView(
                        categories: questionManager.categories,
                        selectedCategory: $selectedCategory
                    )
                case .questionSelection:
                    if let categoryId = selectedCategory?.id {
                        QuestionSelectionView(
                            questions: questionManager.questions(for: categoryId),
                            selectedQuestion: $selectedQuestion
                        )
                    }
                }
            }
            .onChange(of: selectedCategory) { newCategory in
                // Сбрасываем выбранный вопрос при изменении категории
                if selectedQuestion != nil {
                    selectedQuestion = nil
                }
                // Также сбрасываем пользовательский вопрос
                if isUsingCustomQuestion {
                    isUsingCustomQuestion = false
                    customQuestion = ""
                }
            }
            .onAppear {
                loadData()
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    var isFormValid: Bool {
        !clientName.isEmpty &&
        !clientAge.isEmpty &&
        selectedCategory != nil &&
        (isUsingCustomQuestion ? !customQuestion.isEmpty : selectedQuestion != nil)
    }
    
    private func loadData() {
        isLoading = true
        questionManager.loadCategoriesAndQuestions {
            isLoading = false
        }
    }
    
    private func startReading() {
        // TODO: Implement starting a reading session
        print("Starting reading for client: \(clientName), age: \(clientAge)")
        
        if isUsingCustomQuestion, let categoryId = selectedCategory?.id {
            // Submit custom question for moderation
            questionManager.submitCustomQuestion(
                categoryId: categoryId,
                questionText: customQuestion
            )
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
