//
//  MeioPagamento.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

import SwiftUI

enum MeioPagamento: Identifiable, Equatable {

    case cartao(CartaoModel)
    case conta(ContaModel)

    var id: String {
        switch self {
        case .cartao(let cartao):
            return "cartao-\(cartao.uuid)"
        case .conta(let conta):
            return "conta-\(conta.uuid)"
        }
    }

    var titulo: String {
        switch self {
        case .cartao(let cartao):
            return cartao.nome
        case .conta(let conta):
            return conta.nome
        }
    }
    

    var subtitulo: LocalizedStringKey {
        switch self {
        case .cartao:
            return "Cartão"
        case .conta:
            return "Conta"
        }
    }
    
    var cartaoModel: CartaoModel? {
        guard case .cartao(let cartao) = self else { return nil }
        return cartao
    }
    
    var contaModel: ContaModel? {
        guard case .conta(let conta) = self else { return nil }
        return conta
    }
   
    static func == (lhs: MeioPagamento, rhs: MeioPagamento) -> Bool {
        switch (lhs, rhs) {
        case (.cartao(let c1), .cartao(let c2)):
            return c1.uuid == c2.uuid

        case (.conta(let c1), .conta(let c2)):
            return c1.uuid == c2.uuid

        default:
            return false
        }
    }
}
