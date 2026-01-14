//
//  AnalyticsScreen.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 08/01/26.
//


import FirebaseAnalytics

enum AnalyticsScreen: String {
    case login
    case register
    case home
    case settings
}

enum AnalyticsAuthMethod: String {
    case email
    case apple
    case google
}

final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Screens

    func logScreen(_ screen: AnalyticsScreen, viewClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: viewClass
        ])
    }

    // MARK: - Auth

    func loginAttempt(method: AnalyticsAuthMethod) {
        Analytics.logEvent("login_attempt", parameters: [
            "method": method.rawValue
        ])
    }

    func loginSuccess(method: AnalyticsAuthMethod) {
        Analytics.logEvent("login_success", parameters: [
            "method": method.rawValue
        ])
    }

    func loginError(method: AnalyticsAuthMethod, code: Int) {
        Analytics.logEvent("login_error", parameters: [
            "method": method.rawValue,
            "code": code
        ])
    }

    func signUpCompleted(method: AnalyticsAuthMethod) {
        Analytics.logEvent("sign_up_complete", parameters: [
            "method": method.rawValue
        ])
    }

    func logout() {
        Analytics.logEvent("logout", parameters: nil)
    }

    func passwordResetRequested() {
        Analytics.logEvent("password_reset_request", parameters: nil)
    }
   
    func accountDeleted() {
        Analytics.logEvent("account_deleted", parameters: nil)
    }
}
