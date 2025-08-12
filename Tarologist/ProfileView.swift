//
//  ProfileView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Экран профиля: показывает имя пользователя, статус подписки, позволяет оплатить и выйти
struct ProfileView: View {
    @State private var isSubscribed = false
    @State private var showLoginScreen = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("Загрузка...")
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)

                Text("Профиль")
                    .font(.title2)
                
                if let user = Auth.auth().currentUser {
                    Text("Логин: \(user.email?.replacingOccurrences(of: "@example.com", with: "") ?? "неизвестно")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                if isSubscribed {
                    Text("Подписка активна ✅")
                        .foregroundColor(.green)
                        .font(.headline)
                } else {
                    Text("Подписка неактивна ❌")
                        .foregroundColor(.red)
                        .font(.headline)

                    Button("Оформить подписку") {
                        //startPaymentFlow()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

                Spacer()

                Button("Выйти из аккаунта") {
                    try? Auth.auth().signOut()
                    showLoginScreen = true
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .onAppear {
            //checkSubscription()
        }
        .fullScreenCover(isPresented: $showLoginScreen) {
            LoginRegisterView {
                showLoginScreen = false
                //checkSubscription()
            }
        }
    }

//    // MARK: - Проверка подписки
//
//    private func checkSubscription() {
//        isLoading = true
//        UserService.shared.hasActiveSubscription { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let active):
//                    self.isSubscribed = active
//                    self.errorMessage = nil
//                case .failure(let error):
//                    self.errorMessage = error.localizedDescription
//                }
//                self.isLoading = false
//            }
//        }
//    }

//    // MARK: - Запуск оплаты
//
//    private func startPaymentFlow() {
//        PaymentService.shared.startSubscriptionPayment { success, error in
//            if success {
//                checkSubscription()
//            } else {
//                self.errorMessage = error?.localizedDescription ?? "Ошибка при оплате"
//            }
//        }
//    }
}
