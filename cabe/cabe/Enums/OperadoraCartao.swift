//
//  OperadoraCartao.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import Foundation


enum OperadoraCartao: Int, CaseIterable, Identifiable {
    case visa = 1
    case mastercard = 2
    case amex = 3
    case diners = 4
    case hipercard = 5
    case elo = 6
    case outra = 7

    var id: Int { rawValue }

    var nome: LocalizedStringResource {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .diners: return "Diners Club"
        case .hipercard: return "Hipercard"
        case .elo: return "Elo"
        case .outra: return "Outra Operadora"
        }
    }

    var imageName: String {
        switch self {
        case .visa: return "visa"
        case .mastercard: return "mastercard"
        case .amex: return "amex"
        case .diners: return "diners"
        case .hipercard: return "hipercard"
        case .elo: return "elo"
        case .outra: return "outra"
        }
    }
}
