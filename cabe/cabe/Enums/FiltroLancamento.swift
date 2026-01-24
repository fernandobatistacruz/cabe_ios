//
//  FiltroLancamento.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/01/26.
//


enum FiltroLancamento: String, CaseIterable, Identifiable {
    case todos
    case parcelados
    case divididos
    case recorrentes

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .todos: return "Todos"
        case .parcelados: return "Parcelados"
        case .divididos: return "Divididos"
        case .recorrentes: return "Recorrentes"
        }
    }
}

enum FiltroTipo: String, CaseIterable, Identifiable {
    case todos
    case receita
    case despesa

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .todos: return "Todos"
        case .receita: return "Receitas"
        case .despesa: return "Despesas"
        }
    }
}
