//
//  QuestionManager.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import Foundation
import FirebaseFirestore
import Combine

class QuestionManager: ObservableObject {
    @Published var categories: [QuestionCategory] = []
    @Published var questions: [Question] = []
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private var categoriesListener: ListenerRegistration?
    private var questionsListener: ListenerRegistration?
    
    func setupRealTimeListeners() {
        // Удаляем существующие слушатели
        removeListeners()
        
        // Слушатель для категорий
        categoriesListener = db.collection("questionCategories")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to categories: \(error.localizedDescription)")
                    self.loadCategoriesFromCache()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No category documents")
                    return
                }
                
                let categories = documents.compactMap { QuestionCategory(document: $0) }
                print("Categories updated: \(categories.count) items")
                
                DispatchQueue.main.async {
                    self.categories = categories
                    self.saveCategoriesToCache(categories)
                }
            }
        
        // Слушатель для вопросов
        questionsListener = db.collection("questions")
            .whereField("isActive", isEqualTo: true)
            .whereField("isApproved", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to questions: \(error.localizedDescription)")
                    self.loadQuestionsFromCache()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No question documents")
                    return
                }
                
                let questions = documents.compactMap { Question(document: $0) }
                print("Questions updated: \(questions.count) items")
                
                DispatchQueue.main.async {
                    self.questions = questions
                    self.saveQuestionsToCache(questions)
                }
            }
    }

    func removeListeners() {
        categoriesListener?.remove()
        questionsListener?.remove()
        categoriesListener = nil
        questionsListener = nil
    }
    
    // MARK: - Load Data
    
    func loadCategoriesAndQuestions(completion: (() -> Void)? = nil) {
        loadCategories {
            self.loadQuestions {
                completion?()
            }
        }
    }
    
    func loadCategories(completion: (() -> Void)? = nil) {
        print("Starting categories loading...")
        db.collection("questionCategories")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading categories: \(error.localizedDescription)")
                    print("Loading categories from cache...")
                    DispatchQueue.main.async {
                        self.loadCategoriesFromCache()
                    }
                } else {
                    print("Successfully loaded from Firestore")
                    let categories = snapshot?.documents.compactMap { QuestionCategory(document: $0) } ?? []
                    print("Found \(categories.count) categories")
                    
                    // Логируем первые несколько категорий для проверки
                    for category in categories.prefix(3) {
                        print("Category: \(category.name), ID: \(category.id)")
                    }
                    
                    DispatchQueue.main.async {
                        self.categories = categories
                        self.saveCategoriesToCache(categories)
                        print("Categories updated in UI")
                    }
                }
                completion?()
            }
    }
    
    func refreshData() {
        removeListeners()
        setupRealTimeListeners()
    }
    
    func loadQuestions(completion: (() -> Void)? = nil) {
        db.collection("questions")
            .whereField("isActive", isEqualTo: true)
            .whereField("isApproved", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading questions: \(error.localizedDescription)")
                    // Try to load from cache
                    self.loadQuestionsFromCache()
                } else {
                    let questions = snapshot?.documents.compactMap { Question(document: $0) } ?? []
                    self.questions = questions
                    self.saveQuestionsToCache(questions)
                }
                completion?()
            }
    }
    
    func questions(for categoryId: String) -> [Question] {
        return questions.filter { $0.categoryId == categoryId }
    }
    
    // MARK: - Custom Question Submission
    
    func submitCustomQuestion(categoryId: String, questionText: String) {
        let question = Question(
            id: UUID().uuidString,
            categoryId: categoryId,
            text: questionText,
            isApproved: false,
            isActive: true
        )
        
        do {
            try db.collection("questions").document(question.id).setData(from: question)
            print("Custom question submitted for moderation")
        } catch {
            print("Error submitting custom question: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cache Management
    
    private func saveCategoriesToCache(_ categories: [QuestionCategory]) {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "cachedQuestionCategories")
        }
    }
    
    private func loadCategoriesFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedQuestionCategories"),
           let categories = try? JSONDecoder().decode([QuestionCategory].self, from: data) {
            self.categories = categories
        }
    }
    
    private func saveQuestionsToCache(_ questions: [Question]) {
        if let encoded = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encoded, forKey: "cachedQuestions")
        }
    }
    
    private func loadQuestionsFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedQuestions"),
           let questions = try? JSONDecoder().decode([Question].self, from: data) {
            self.questions = questions
        }
    }
}
