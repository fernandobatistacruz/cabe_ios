//
//  Decimal+App.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 07/03/26.
//
import Foundation

extension Decimal {

    func abreviado(
        currencyCode: String,
        locale: Locale = .current
    ) -> String {

        let value = NSDecimalNumber(decimal: self).doubleValue
        let absValue = abs(value)

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = absValue >= 1_000 ? 1 : 0
        
        formatter.currencySymbol = ""
        formatter.internationalCurrencySymbol = ""
        formatter.positivePrefix = ""
        formatter.positiveSuffix = ""
        formatter.negativePrefix = "-"
        formatter.negativeSuffix = ""

        let thousandSuffix = String(
            localized: "suffix_thousand",
            bundle: .main
        )

        let millionSuffix = String(
            localized: "suffix_million",
            bundle: .main
        )

        switch absValue {
        case 1_000_000...:
            let number = value / 1_000_000
            let formatted = formatter.string(from: NSNumber(value: number)) ?? ""
            return "\(formatted) \(millionSuffix)"

        case 1_000...:
            let number = value / 1_000
            let formatted = formatter.string(from: NSNumber(value: number)) ?? ""
            return "\(formatted) \(thousandSuffix)"

        default:
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? ""
        }
    }
}
