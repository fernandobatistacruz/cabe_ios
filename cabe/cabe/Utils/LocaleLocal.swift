//
//  LocaleLocal.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/01/26.
//

import Foundation

extension Locale {
    static var systemCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
