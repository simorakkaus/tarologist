//
//  FinalizeReadingView.swift
//  Tarologist
//
//  Created by Simo on 06.08.2025.
//

import SwiftUI
import UIKit

/// Финальный экран — предпросмотр и действия с готовым толкованием
struct FinalizeReadingView: View {
    let sessionId: String
    let summary: String

    @State private var showShareSheet = false
    @State private var showCopyAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Итоговое толкование")
                .font(.title2)

            ScrollView {
                Text(summary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }

            HStack(spacing: 16) {
                Button(action: {
                    UIPasteboard.general.string = summary
                    showCopyAlert = true
                }) {
                    Label("Скопировать", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    showShareSheet = true
                }) {
                    Label("Отправить", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Отправка")
        .alert(isPresented: $showCopyAlert) {
            Alert(title: Text("Скопировано"), message: Text("Толкование скопировано в буфер обмена"), dismissButton: .default(Text("Ок")))
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [summary])
        }
    }
}

/// UIKit-обёртка для Share Sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
