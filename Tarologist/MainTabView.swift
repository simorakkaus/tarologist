//
//  MainTabView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI

/// Главный контейнер вкладок: "Гадание" и "Профиль"
struct MainTabView: View {
    var body: some View {
        TabView {
            /// Первая вкладка — история и запуск нового гадания
            NavigationView {
                SessionsListView()
            }
            .tabItem {
                Image(systemName: "plus.square.on.square")
                Text("Гадание")
            }

            /// Вторая вкладка — профиль, управление подпиской и выход
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Профиль")
            }
        }
    }
}
#Preview {
    MainTabView()
}