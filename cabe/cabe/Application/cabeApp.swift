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
    @StateObject private var auth = AuthViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        _ = AppDatabase.shared
        appDelegate.deepLinkManager = deepLinkManager
    }

    var body: some Scene {
        WindowGroup {
            Group{
                switch auth.state {
                case .loading:
                    ProgressView()                   
                case .unauthenticated:
                    LoginView()
                case .authenticated:
                    TabMenuView()
                }
            }
            .environmentObject(subscriptionManager)
            .environmentObject(themeManager)
            .environmentObject(deepLinkManager)
            .environmentObject(auth)
            .preferredColorScheme(colorScheme)
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
