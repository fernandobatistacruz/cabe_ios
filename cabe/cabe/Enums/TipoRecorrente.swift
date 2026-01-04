//
//  Repeticao.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

import SwiftUI


enum TipoRecorrente: Int, CaseIterable, Identifiable {
    case nunca      = 0
    case mensal     = 1
    case quinzenal  = 2
    case semanal    = 3
    case parcelado  = 4

    var id: Int { rawValue }

    var titulo: LocalizedStringKey {
        switch self {
        case .nunca:      return "Nunca"
        case .mensal:     return "Mensal"
        case .quinzenal:  return "Quinzenal"
        case .semanal:    return "Semanal"
        case .parcelado:  return "Parcelado"
        }
    }
}

