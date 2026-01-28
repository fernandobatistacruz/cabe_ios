//
//  AppDateFormatter.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/01/26.
//

import Foundation

enum DataCivil {

    static func hojeString() -> String {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month, .day], from: Date())

        return String(
            format: "%04d-%02d-%02d",
            c.year!,
            c.month!,
            c.day!
        )
    }
}

enum DataCriacaoParser {

    static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let isoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
