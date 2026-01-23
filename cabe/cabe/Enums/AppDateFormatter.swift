//
//  AppDateFormatter.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/01/26.
//

import Foundation


enum AppDateFormatter {

    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}
