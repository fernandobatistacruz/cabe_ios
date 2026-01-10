//
//  AppDelegate.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 09/01/26.
//

import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var deepLinkManager: DeepLinkManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self       
        FirebaseApp.configure()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        if userInfo["destino"] as? String == "notificacoes" {
            await MainActor.run {
                self.deepLinkManager?.open(.notificacoes)
            }
        }
    }
}
