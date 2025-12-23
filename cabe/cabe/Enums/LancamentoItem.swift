//
//  LancamentoItem.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import Foundation

enum LancamentoItem: Identifiable {
    case simples(LancamentoModel)
    case cartaoAgrupado(
        cartao: CartaoModel,
        total: Decimal,
        lancamentos: [LancamentoModel]
    )

    var id: String {
        switch self {
        case .simples(let l):
            return "simples-\(l.id ?? 0)"
        case .cartaoAgrupado(let cartao, _, _):
            return "cartao-\(cartao.id ?? 0)"
        }
    }
}
