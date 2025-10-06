//
//  RootViewSwitcher.swift
//  Tarologist
//
//  Created by Simo on 06.10.2025.
//

import SwiftUI

struct RootViewSwitcher: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingScreenView()
            } else {
                if authManager.isLoggedIn {
                    MainTabView()
                } else {
                    LoginRegisterView()
                }
            }
        }
    }
}
