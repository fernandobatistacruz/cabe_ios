//
//  AppearanceSettingsView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 26/01/26.
//

import SwiftUI
import Combine


struct AppearanceSettingsView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    themeRow(
                        title: String(localized: "Automático"),
                        theme: .system
                    )

                    themeRow(
                        title:  String(localized: "Claro"),
                        theme: .light
                    )

                    themeRow(
                        title:  String(localized: "Escuro"),
                        theme: .dark
                    )
                } footer: {
                    Text("Escolha como o app deve se comportar em relação ao modo Claro e Escuro.")
                }
            }
            .navigationTitle("Aparência")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private func themeRow(
        title: String,
        theme: ThemeManager.Theme
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            if themeManager.theme == theme {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            themeManager.theme = theme
            dismiss()
        }
    }
}

final class ThemeManager: ObservableObject {

    enum Theme: String, CaseIterable {
        case system
        case light
        case dark

        var title: LocalizedStringKey {
            switch self {
            case .system:
                return "theme.system"
            case .light:
                return "theme.light"
            case .dark:
                return "theme.dark"
            }
        }
    }

    @Published var theme: Theme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        theme = Theme(rawValue: saved ?? "") ?? .system
    }
}
