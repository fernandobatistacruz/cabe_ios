//
//  FiltroLancamento.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/01/26.
//

import Foundation


enum FiltroLancamento: String, CaseIterable, Identifiable {
    case todos
    case parcelados
    case recorrentes
    case pagos
    case naoPagos

    var id: String { rawValue }

    var titulo: LocalizedStringResource {
        switch self {
        case .todos: return "Todos"
        case .parcelados: return "Parcelados"
        case .recorrentes: return "Recorrentes"       
        case .pagos: return "Pagos"
        case .naoPagos: return "Não Pagos"
        }
    }
}

enum FiltroLancamentoFatura: String, CaseIterable, Identifiable {
    case todos
    case parcelados
    case recorrentes
    case divididos

    var id: String { rawValue }

    var titulo: LocalizedStringResource {
        switch self {
        case .todos: return "Todos"
        case .parcelados: return "Parcelados"
        case .recorrentes: return "Recorrentes"
        case .divididos: return "Divididos"
        }
    }
}

enum FiltroTipo: String, CaseIterable, Identifiable {
    case todos
    case receita
    case despesa

    var id: String { rawValue }

    var titulo: LocalizedStringResource {
        switch self {
        case .todos: return "Todos"
        case .receita: return "Receitas"
        case .despesa: return "Despesas"
        }
    }
}
