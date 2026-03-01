//
//  ReviewRequestService.swift
//  cabe
//
//  Created by Codex on 01/03/26.
//

import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewRequestService {

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func handleAppDidBecomeActive(isAuthenticated: Bool) {
        let now = Date()
        registerInstallDateIfNeeded(now: now)
        incrementOpenCount()

        guard isAuthenticated else { return }
        guard shouldRequestReview(now: now) else { return }

        requestReview(afterDelay: 1_000_000_000)
        markPromptRequested(now: now)
    }

    private func registerInstallDateIfNeeded(now: Date) {
        if defaults.object(forKey: AppSettings.reviewInstallDate) == nil {
            defaults.set(now, forKey: AppSettings.reviewInstallDate)
        }
    }

    private func incrementOpenCount() {
        let current = defaults.integer(forKey: AppSettings.reviewOpenCount)
        defaults.set(current + 1, forKey: AppSettings.reviewOpenCount)
    }

    private func shouldRequestReview(now: Date) -> Bool {
        let openCount = defaults.integer(forKey: AppSettings.reviewOpenCount)
        guard ReviewMilestones.values.contains(openCount) else { return false }

        guard let installDate = defaults.object(forKey: AppSettings.reviewInstallDate) as? Date else {
            return false
        }

        guard let daysSinceInstall = calendar.dateComponents([.day], from: installDate, to: now).day,
              daysSinceInstall >= 14 else {
            return false
        }

        if let lastRequestDate = defaults.object(forKey: AppSettings.reviewLastRequestDate) as? Date {
            let daysSinceLastRequest = calendar.dateComponents([.day], from: lastRequestDate, to: now).day ?? 0
            guard daysSinceLastRequest >= 180 else { return false }
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let lastVersion = defaults.string(forKey: AppSettings.reviewLastRequestVersion)
        if currentVersion == lastVersion {
            return false
        }

        return activeWindowScene() != nil
    }

    private func requestReview(afterDelay delayNanoseconds: UInt64) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard let scene = activeWindowScene() else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func markPromptRequested(now: Date) {
        defaults.set(now, forKey: AppSettings.reviewLastRequestDate)
        if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            defaults.set(currentVersion, forKey: AppSettings.reviewLastRequestVersion)
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
    }
}

private enum ReviewMilestones {
    static let values: Set<Int> = [10, 25, 50, 100]
}
