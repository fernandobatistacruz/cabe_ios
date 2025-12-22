//
//  FiltroCartao.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//


enum FiltroCartao: Int, CaseIterable, Identifiable {
    case ativos
    case arquivados

    var id: Int { rawValue }

    var titulo: String {
        switch self {
        case .ativos:
            return "Ativos"
        case .arquivados:
            return "Arquivados"
        }
    }

    /// Mapeia para o valor salvo no banco
    var valorArquivado: Int {
        switch self {
        case .ativos:
            return 0
        case .arquivados:
            return 1
        }
    }
}
