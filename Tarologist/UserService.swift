//
//  UserService.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Сервис работы с пользователем и подпиской
class UserService {
    static let shared = UserService()
    private init() {}

    private let db = Firestore.firestore()

    /// Проверяет, есть ли у пользователя активная подписка
    func hasActiveSubscription(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Ошибка получения документа пользователя: \(error.localizedDescription)")
                completion(false)
                return
            }

            let isSubscribed = snapshot?.data()?["isSubscribed"] as? Bool ?? false
            completion(isSubscribed)
        }
    }

    /// Активирует подписку пользователю (например, после оплаты)
    func activateSubscription(completion: ((Bool) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(false)
            return
        }

        db.collection("users").document(userId).setData([
            "isSubscribed": true,
            "subscriptionActivatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Ошибка активации подписки: \(error.localizedDescription)")
                completion?(false)
            } else {
                completion?(true)
            }
        }
    }

    /// Сброс подписки (например, для отладки)
    func deactivateSubscription(completion: ((Bool) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(false)
            return
        }

        db.collection("users").document(userId).setData([
            "isSubscribed": false
        ], merge: true) { error in
            if let error = error {
                print("Ошибка сброса подписки: \(error.localizedDescription)")
                completion?(false)
            } else {
                completion?(true)
            }
        }
    }
}
