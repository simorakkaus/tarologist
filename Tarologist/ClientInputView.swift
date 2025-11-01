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
    
    // MARK: - Computed Properties
    private var hasSelectedQuestion: Bool {
        (selectedQuestion != nil) || (isUsingCustomQuestion && !customQuestion.isEmpty)
    }
    
    private var isFormValid: Bool {
        !clientName.isEmpty &&
        !clientAge.isEmpty &&
        selectedCategory != nil &&
        hasSelectedQuestion &&
        selectedSpread != nil
    }
    
    // MARK: - Main Body
    var body: some View {
        ZStack {
            backgroundContent
            mainContent
            loadingIndicator
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
        .background(navigationLink)
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
            handleCategoryChange()
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
    
    // MARK: - Subviews
    private var backgroundContent: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
    }
    
    private var mainContent: some View {
        VStack {
            formContent
            startButton
        }
    }
    
    private var formContent: some View {
        Form {
            clientInfoSection
            categorySection
            questionSection
            spreadSection
            supportSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var clientInfoSection: some View {
        Section(header: Text("Данные клиента")) {
            nameField
            ageField
            errorMessageView
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    private var nameField: some View {
        TextField("Имя клиента", text: $clientName)
            .focused($focusedField, equals: .clientName)
            .submitLabel(.next)
            .onSubmit {
                focusedField = .clientAge
            }
    }
    
    private var ageField: some View {
        TextField("Возраст клиента", text: $clientAge)
            .focused($focusedField, equals: .clientAge)
            .keyboardType(.numberPad)
            .submitLabel(.done)
            .onSubmit {
                hideKeyboard()
            }
            .onChange(of: clientAge) { newValue in
                handleAgeChange(newValue)
            }
    }
    
    private var errorMessageView: some View {
        Group {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
                    .animation(.easeInOut, value: errorMessage)
            }
        }
    }
    
    private var categorySection: some View {
        Section(
            header: HStack {
                Text("Категория вопроса")
                Spacer()
                if selectedCategory != nil {
                    Button("Изменить") {
                        hideKeyboard()
                        activeSheet = .categorySelection
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                }
            }
        ) {
            if let selectedCategory = selectedCategory {
                Button(action: {
                    hideKeyboard()
                    activeSheet = .categorySelection
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedCategory.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        if let description = selectedCategory.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button("Выберите категорию вопроса") {
                    hideKeyboard()
                    activeSheet = .categorySelection
                }
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var questionSection: some View {
        if selectedCategory != nil {
            Section(
                header: HStack {
                    Text("Вопрос")
                    Spacer()
                    if selectedQuestion != nil && !isUsingCustomQuestion {
                        Button("Изменить") {
                            hideKeyboard()
                            activeSheet = .questionSelection
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
                    }
                }
            ) {
                if isUsingCustomQuestion {
                    customQuestionField
                } else {
                    predefinedQuestionContent
                }
            }
            .listRowBackground(Color(.systemGroupedBackground))
        }
    }

    private var predefinedQuestionContent: some View {
        Group {
            if let selectedQuestion = selectedQuestion {
                Button(action: {
                    hideKeyboard()
                    activeSheet = .questionSelection
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedQuestion.text)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Не нашли подходящий вопрос?") {
                    hideKeyboard()
                    isUsingCustomQuestion = true
                    focusedField = .customQuestion
                }
                .foregroundColor(.blue)
            } else {
                Button("Выберите вопрос") {
                    hideKeyboard()
                    activeSheet = .questionSelection
                }
            }
        }
    }

    private var customQuestionField: some View {
        Group {
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
    
    @ViewBuilder
    private var spreadSection: some View {
        if hasSelectedQuestion {
            Section(
                header: HStack {
                    Text("Тип расклада")
                    Spacer()
                    if selectedSpread != nil {
                        Button("Изменить") {
                            hideKeyboard()
                            activeSheet = .spreadSelection
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
                    }
                }
            ) {
                if let selectedSpread = selectedSpread {
                    Button(action: {
                        hideKeyboard()
                        activeSheet = .spreadSelection
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedSpread.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(selectedSpread.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Карт: \(selectedSpread.numberOfCards)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button("Выберите тип расклада") {
                        hideKeyboard()
                        activeSheet = .spreadSelection
                    }
                }
            }
            .listRowBackground(Color(.systemGroupedBackground))
        }
    }
    
    private var supportSection: some View {
        Section(header: Text("Поддержка")) {
            Button("Предложить новую категорию или вопрос") {
                hideKeyboard()
                activeSheet = .suggestion
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    private var startButton: some View {
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
    
    private var loadingIndicator: some View {
        Group {
            if questionManager.categories.isEmpty {
                ProgressView("Загрузка категорий...")
                    .scaleEffect(1.5)
            }
        }
    }
    
    private var navigationLink: some View {
        Group {
            if let spread = selectedSpread {
                NavigationLink(
                    destination: CardReadingView(
                        clientName: clientName,
                        clientAge: clientAge,
                        questionCategory: selectedCategory!,
                        question: selectedQuestion,
                        customQuestion: isUsingCustomQuestion ? customQuestion : nil,
                        selectedSpread: spread
                    ),
                    isActive: $navigateToReading,
                    label: { EmptyView() }
                )
            }
        }
    }
    
    // MARK: - View Modifiers
    private var navigationSetup: some View {
        Group {
            self.navigationTitle("Новое гадание")
            self.navigationBarBackButtonHidden(true)
            self.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отменить") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var sheetHandling: some View {
        self.sheet(item: $activeSheet) { item in
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
    }
    
    private var onChangeHandling: some View {
        Group {
            self.onChange(of: selectedCategory) { _ in
                handleCategoryChange()
            }
            self.onChange(of: selectedQuestion) { _ in
                selectedSpread = nil
            }
            self.onChange(of: isUsingCustomQuestion) { _ in
                selectedSpread = nil
            }
        }
    }
    
    private var lifecycleHandling: some View {
        Group {
            self.onAppear {
                questionManager.setupRealTimeListeners()
                spreadManager.loadSpreads()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .clientName
                }
            }
            self.onDisappear {
                questionManager.removeListeners()
            }
            self.refreshable {
                questionManager.removeListeners()
                questionManager.setupRealTimeListeners()
                spreadManager.loadSpreads()
            }
        }
    }
    
    // MARK: - Methods
    private func handleAgeChange(_ newValue: String) {
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
    
    private func handleCategoryChange() {
        if selectedQuestion != nil {
            selectedQuestion = nil
        }
        if isUsingCustomQuestion {
            isUsingCustomQuestion = false
            customQuestion = ""
        }
        selectedSpread = nil
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
