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
    
    // MARK: - Load Data
    
    func loadCategoriesAndQuestions(completion: (() -> Void)? = nil) {
        loadCategories {
            self.loadQuestions {
                completion?()
            }
        }
    }
    
    func loadCategories(completion: (() -> Void)? = nil) {
        db.collection("questionCategories")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading categories: \(error.localizedDescription)")
                    // Try to load from cache
                    self.loadCategoriesFromCache()
                } else {
                    let categories = snapshot?.documents.compactMap { QuestionCategory(document: $0) } ?? []
                    self.categories = categories
                    self.saveCategoriesToCache(categories)
                }
                completion?()
            }
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
