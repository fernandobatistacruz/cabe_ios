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
    case discover = 8
    case renner = 9
    case cea = 10
    case riachuelo = 11

    var id: Int { rawValue }

    var nome: LocalizedStringResource {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .diners: return "Diners Club"
        case .hipercard: return "Hipercard"
        case .elo: return "Elo"
        case .outra: return "Outras"
        case .discover: return "Discover"
        case .renner: return "Renner"
        case .cea: return "C&A"
        case .riachuelo: return "Riachuelo"
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
        case .discover: return "discover"
        case .renner: return "renner"
        case .cea: return "cea"
        case .riachuelo: return "riachuelo"
        }
    }
}

extension OperadoraCartao {
    
    var exclusivaBrasil: Bool {
        switch self {
        case .elo, .hipercard, .renner, .cea, .riachuelo:
            return true
        default:
            return false
        }
    }

    static var disponiveisParaRegiaoAtual: [OperadoraCartao] {
        let isBrasil = Locale.current.region?.identifier == "BR"

        return allCases.filter {
            isBrasil || !$0.exclusivaBrasil
        }
    }
}
