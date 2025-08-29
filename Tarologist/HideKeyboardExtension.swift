//
//  HideKeyboardExtension.swift
//  Tarologist
//
//  Created by Simo on 29.08.2025.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
