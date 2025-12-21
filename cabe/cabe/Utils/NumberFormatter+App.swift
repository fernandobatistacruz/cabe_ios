import Foundation

extension NumberFormatter {
    
    static let decimalInput: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = .current
        f.generatesDecimalNumbers = true
        return f
    }()
}
