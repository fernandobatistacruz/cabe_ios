//
//  cabeApp.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI

enum AppBootstrap {
    
    /// Deve ser síncrono para evitar abrir o banco antes do restore.
    static func prepare() {
        do {
            try BackupService.shared.restaurarSeNecessario()
        } catch {
            print("Erro ao restaurar backup:", error)
        }
        _ = AppDatabase.shared
    }
}

@main
struct cabeApp: App {

    @StateObject private var themeManager = ThemeManager()
    let deepLinkManager = DeepLinkManager()
    @StateObject private var auth = AuthViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    let backupVM = BackupViewModel()
        
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    private let notificationService = NotificationService()
    
    @Environment(\.scenePhase)
    private var scenePhase

    init() {
        DispatchQueue.global(qos: .utility).sync {
            AppBootstrap.prepare()
        }
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
            .onChange(of: scenePhase) { phase in
                switch phase {
                    
                case .active:
                    Task.detached(priority: .utility) {
                        await notificationService.atualizarNotificacoes()
                    }
                    
                case .background:
                    if BackupPolicy.deveFazerBackupAutomatico() {
                        backupVM.fazerBackupManual()
                    }
                    
                default:
                    break
                }
            }
            .environmentObject(subscriptionManager)
            .environmentObject(themeManager)
            .environmentObject(deepLinkManager)
            .environmentObject(auth)
            .environmentObject(backupVM)
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
