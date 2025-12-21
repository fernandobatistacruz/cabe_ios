//
//  NumberFormatter+App.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 21/12/25.
//

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
