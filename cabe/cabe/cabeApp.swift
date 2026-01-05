//
//  cabeApp.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI

@main
struct cabeApp: App {

    @StateObject private var themeManager = ThemeManager()
    @StateObject private var deepLinkManager = DeepLinkManager()

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        _ = AppDatabase.shared
    }

    var body: some Scene {
        WindowGroup {
            TabMenuView()
                .environmentObject(themeManager)
                .environmentObject(deepLinkManager)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    appDelegate.deepLinkManager = deepLinkManager
                }
            
        }
    }

    private var colorScheme: ColorScheme? {
        switch themeManager.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}


