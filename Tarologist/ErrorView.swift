//
//  ErrorView.swift
//  Tarologist
//
//  Created by Simo on 24.10.2025.
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let primaryAction: (title: String, action: () -> Void)
    
    init(
        title: String,
        description: String,
        iconName: String,
        iconColor: Color,
        primaryAction: (title: String, action: () -> Void)
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.iconColor = iconColor
        self.primaryAction = primaryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Иконка ошибки (теперь параметризированная)
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(iconColor)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, options: .nonRepeating)
            
            // Заголовок
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Описание
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Основная кнопка действия
            Button(action: primaryAction.action) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 44))
                    .frame(minWidth: 44, minHeight: 44)
                    .symbolRenderingMode(.hierarchical)
                    .contentShape(Circle())
            }
            
            Spacer()
        }
        .padding()
    }
}

// Расширение для удобного создания стандартных ошибок
extension ErrorView {
    static func sessionsLoadingError(
        onRetry: @escaping () -> Void
    ) -> ErrorView {
        ErrorView(
            title: "Ошибка загрузки",
            description: "Не удалось загрузить список ваших раскладов. Пожалуйста, проверьте подключение к интернету и попробуйте снова.",
            iconName: "rectangle.stack.fill.badge.minus",
            iconColor: .red,
            primaryAction: (title: "Повторить попытку", action: onRetry)
        )
    }
    
    static func networkError(
        onRetry: @escaping () -> Void
    ) -> ErrorView {
        ErrorView(
            title: "Нет подключения",
            description: "Отсутствует подключение к интернету. Пожалуйста, проверьте ваше соединение и попробуйте снова.",
            iconName: "wifi.exclamationmark",
            iconColor: .red,
            primaryAction: (title: "Повторить попытку", action: onRetry)
        )
    }
    
    static func dataNotFoundError(
        onRetry: @escaping () -> Void
    ) -> ErrorView {
        ErrorView(
            title: "Данные не найдены",
            description: "Запрошенная информация временно недоступна или была удалена.",
            iconName: "doc.text.magnifyingglass",
            iconColor: .red,
            primaryAction: (title: "Обновить", action: onRetry)
        )
    }
    
    static func authError(
        onRetry: @escaping () -> Void
    ) -> ErrorView {
        ErrorView(
            title: "Ошибка авторизации",
            description: "Не удалось выполнить вход. Пожалуйста, проверьте ваши учетные данные и попробуйте снова.",
            iconName: "person.crop.circle.badge.exclamationmark",
            iconColor: .red,
            primaryAction: (title: "Попробовать снова", action: onRetry)
        )
    }
    
    static func serverError(
        onRetry: @escaping () -> Void
    ) -> ErrorView {
        ErrorView(
            title: "Ошибка сервера",
            description: "Сервер временно недоступен. Пожалуйста, попробуйте позже.",
            iconName: "desktopcomputer.trianglebadge.exclamationmark",
            iconColor: .red,
            primaryAction: (title: "Повторить", action: onRetry)
        )
    }
}

// Отдельные превью для каждого типа ошибок
#Preview("Ошибка загрузки сессий") {
    ErrorView.sessionsLoadingError(
        onRetry: {
            print("Повторить загрузку сессий")
        }
    )
}

#Preview("Ошибка сети") {
    ErrorView.networkError(
        onRetry: {
            print("Повторить сетевое соединение")
        }
    )
}

#Preview("Данные не найдены") {
    ErrorView.dataNotFoundError(
        onRetry: {
            print("Обновить данные")
        }
    )
}

#Preview("Ошибка авторизации") {
    ErrorView.authError(
        onRetry: {
            print("Повторить авторизацию")
        }
    )
}

#Preview("Ошибка сервера") {
    ErrorView.serverError(
        onRetry: {
            print("Повторить запрос к серверу")
        }
    )
}

#Preview("Стандартная ошибка") {
    ErrorView(
        title: "Простая ошибка",
        description: "Что-то пошло не так, но это не критично.",
        iconName: "exclamationmark.triangle.fill",
        iconColor: .orange,
        primaryAction: (title: "Понятно", action: {
            print("Закрыть уведомление")
        })
    )
}
