//
//  Repeticao.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

import SwiftUI


enum TipoRecorrente: Int, CaseIterable, Identifiable {
    case nunca      = 0
    case semanal    = 3
    case quinzenal  = 2
    case mensal     = 1
    case trimestral = 7
    case semestral  = 6
    case anual      = 5
    case parcelado  = 4

    var id: Int { rawValue }

    var titulo: LocalizedStringKey {
        switch self {
        case .nunca:      return "Nunca"
        case .mensal:     return "Mensal"
        case .quinzenal:  return "Quinzenal"
        case .semanal:    return "Semanal"
        case .parcelado:  return "Parcelado"
        case .anual:      return "Anual"
        case .semestral:  return "Semestral"
        case .trimestral: return "Trimestral"
        }
    }
}

