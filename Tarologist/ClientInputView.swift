//
//  ClientInputView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseFirestore

enum ActiveSheet: Identifiable {
    case categorySelection
    case questionSelection
    case suggestion
    case spreadSelection
    
    var id: Int {
        hashValue
    }
}

struct ClientInputView: View {
    @Environment(\.dismiss) var dismiss
    @State private var clientName: String = ""
    @State private var clientAge: String = ""
    @State private var selectedCategory: QuestionCategory?
    @State private var selectedQuestion: Question?
    @State private var customQuestion: String = ""
    @State private var isUsingCustomQuestion: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSupportAlert: Bool = false
    @State private var activeSheet: ActiveSheet?
    
    @State private var selectedSpread: Spread?
    @State private var navigateToReading = false
    
    // Для управления фокусом и клавиатурой
    @FocusState private var focusedField: Field?
    
    enum Field {
        case clientName
        case clientAge
        case customQuestion
    }
    
    @StateObject private var questionManager = QuestionManager()
    @StateObject private var spreadManager = SpreadManager()
    
    var body: some View {
        ZStack {
            // Фон для скрытия клавиатуры по тапу
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack {
                Form {
                    // Section 1: Client Information
                    Section(header: Text("Данные клиента")) {
                        TextField("Имя клиента", text: $clientName)
                            .focused($focusedField, equals: .clientName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .clientAge
                            }
                        
                        TextField("Возраст клиента", text: $clientAge)
                            .focused($focusedField, equals: .clientAge)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                            .onSubmit {
                                hideKeyboard()
                            }
                            .onChange(of: clientAge) { newValue in
                                let numbersOnly = newValue.filter { $0.isNumber }
                                let limited = String(numbersOnly.prefix(2))
                                
                                if numbersOnly.count > 2 {
                                    errorMessage = "Возраст не может превышать 99 лет"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        errorMessage = nil
                                    }
                                }
                                
                                if numbersOnly != newValue || numbersOnly.count > 2 {
                                    clientAge = limited
                                }
                                
                                if let age = Int(limited), age > 99 {
                                    clientAge = "99"
                                }
                            }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .transition(.opacity)
                                .animation(.easeInOut, value: errorMessage)
                        }
                    }
                    .listRowBackground(Color(.systemGroupedBackground))
                    
                    // Section 2: Question Category
                    Section(header: Text("Категория вопроса")) {
                        if let selectedCategory = selectedCategory {
                            HStack {
                                Text(selectedCategory.name)
                                Spacer()
                                Button("Изменить") {
                                    hideKeyboard()
                                    activeSheet = .categorySelection
                                }
                                .foregroundColor(.blue)
                            }
                        } else {
                            Button("Выберите категорию вопроса") {
                                hideKeyboard()
                                activeSheet = .categorySelection
                            }
                        }
                    }
                    .listRowBackground(Color(.systemGroupedBackground))
                    
                    // Section 3: Question Selection
                    if selectedCategory != nil {
                        Section(header: Text("Вопрос")) {
                            if !isUsingCustomQuestion {
                                if let selectedQuestion = selectedQuestion {
                                    HStack {
                                        Text(selectedQuestion.text)
                                        Spacer()
                                        Button("Изменить") {
                                            hideKeyboard()
                                            activeSheet = .questionSelection
                                        }
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    Button("Выберите вопрос") {
                                        hideKeyboard()
                                        activeSheet = .questionSelection
                                    }
                                }
                                
                                Button("Не нашли подходящий вопрос?") {
                                    hideKeyboard()
                                    isUsingCustomQuestion = true
                                    focusedField = .customQuestion
                                }
                                .foregroundColor(.blue)
                            } else {
                                TextField("Введите свой вопрос", text: $customQuestion)
                                    .focused($focusedField, equals: .customQuestion)
                                    .lineLimit(3)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        hideKeyboard()
                                    }
                                
                                Button("Вернуться к списку вопросов") {
                                    hideKeyboard()
                                    isUsingCustomQuestion = false
                                    customQuestion = ""
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .listRowBackground(Color(.systemGroupedBackground))
                    }
                    
                    
                    if hasSelectedQuestion {
                        Section(header: Text("Тип расклада")) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedSpread.name)
                                        .font(.headline)
                                    Text(selectedSpread.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Карт: \(selectedSpread.numberOfCards)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Изменить") {
                                    hideKeyboard()
                                    activeSheet = .spreadSelection
                                }
                            }
                        }
                        .listRowBackground(Color(.systemGroupedBackground))
                    }
                    
                    // Section 5: Support Information
                    Section(header: Text("Поддержка")) {
                        Button("Предложить новую категорию или вопрос") {
                            hideKeyboard()
                            activeSheet = .suggestion
                        }
                    }
                    .listRowBackground(Color(.systemGroupedBackground))
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .scrollDismissesKeyboard(.interactively)
                
                Button(action: startReading) {
                    Text("Начать гадание")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(!isFormValid)
            }
            
            if questionManager.categories.isEmpty {
                ProgressView("Загрузка категорий...")
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Новое гадание")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Отменить") {
                    dismiss()
                }
            }
        }
        .background(
            NavigationLink(
                destination: selectedSpread.map { spread in
                    CardReadingView(
                        clientName: clientName,
                        clientAge: clientAge,
                        questionCategory: selectedCategory!,
                        question: selectedQuestion,
                        customQuestion: isUsingCustomQuestion ? customQuestion : nil,
                        selectedSpread: spread
                    )
                },
                isActive: $navigateToReading,
                label: {EmptyView()}
            )
        )
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
            case .suggestion:
                SuggestionView(categories: questionManager.categories)
                
            case .spreadSelection:
                SpreadSelectionSheetView(
                    spreadManager: spreadManager,
                    selectedSpread: $selectedSpread
                )
            }
        }
        .onChange(of: selectedCategory) { _ in
            if selectedQuestion != nil {
                selectedQuestion = nil
            }
            if isUsingCustomQuestion {
                isUsingCustomQuestion = false
                customQuestion = ""
            }
            selectedSpread = nil
        }
        .onChange(of: selectedQuestion) { _ in
            selectedSpread = nil
        }
        .onChange(of: isUsingCustomQuestion) { _ in
            selectedSpread = nil
        }
        .onAppear {
            questionManager.setupRealTimeListeners()
            spreadManager.loadSpreads()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .clientName
            }
        }
        .onDisappear {
            questionManager.removeListeners()
        }
        .refreshable {
            questionManager.removeListeners()
            questionManager.setupRealTimeListeners()
            spreadManager.loadSpreads()
        }
    }
    
    private var hasSelectedQuestion: Bool {
        (selectedQuestion != nil) || (isUsingCustomQuestion && !customQuestion.isEmpty)
    }
    
    var isFormValid: Bool {
        !clientName.isEmpty &&
        !clientAge.isEmpty &&
        selectedCategory != nil &&
        hasSelectedQuestion &&
        selectedSpread != nil
    }
    
    private func loadData() {
        isLoading = true
        questionManager.loadCategoriesAndQuestions {
            isLoading = false
        }
    }
    
    private func startReading() {
        hideKeyboard()
        
        guard let selectedCategory = selectedCategory else {
            errorMessage = "Выберите категорию вопроса"
            return
        }
        
        guard hasSelectedQuestion else {
            errorMessage = "Выберите или введите вопрос"
            return
        }
        
        guard selectedSpread != nil else {
            errorMessage = "Выберите тип расклада"
            return
        }
        
        if isUsingCustomQuestion {
            questionManager.submitCustomQuestion(
                categoryId: selectedCategory.id,
                questionText: customQuestion
            )
        }
        
        navigateToReading = true
        
        print("""
                Начало гадания для клиента:
                - Имя: \(clientName)
                - Возраст: \(clientAge)
                - Категория: \(selectedCategory.name)
                - Вопрос: \(isUsingCustomQuestion ? customQuestion : selectedQuestion?.text ?? "")
                - Расклад: \(selectedSpread?.name ?? "Не выбран")
                """)
    }
    
    private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ClientInputView()
}
