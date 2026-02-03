import Foundation

extension NumberFormatter {
    
    static let decimalInput: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.generatesDecimalNumbers = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}

final class CurrencyFormatter {

    static func formatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

extension Decimal {
    func arredondadoMoeda() -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 2, .bankers)
        return result
    }
}
