//
//  cabeApp.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds

@main
struct cabeApp: App {

    @StateObject private var themeManager = ThemeManager()
    @StateObject private var deepLinkManager = DeepLinkManager()
    @StateObject private var auth = AuthViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        _ = AppDatabase.shared      
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
            .environmentObject(themeManager)
            .environmentObject(deepLinkManager)
            .environmentObject(auth)
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
