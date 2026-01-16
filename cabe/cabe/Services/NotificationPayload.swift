//
//  NotificationPayload.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 15/01/26.
//

import Foundation


// NotificacaoFactory.swift

struct NotificationPayload {
    let lancamentosSimples: [LancamentoModel]
    let cartoes: [CartaoNotificacao]
}

struct NotificacaoFactory {

    static func gerar(
        lancamentos: [LancamentoModel]
    ) -> NotificationPayload {

        let simples = lancamentos.filter {
            $0.cartaoUuid.isEmpty
        }

        let cartao = lancamentos.filter {
            !$0.cartaoUuid.isEmpty
        }

        let cartoesAgrupados = agruparPorCartao(cartao)

        return NotificationPayload(
            lancamentosSimples: simples,
            cartoes: cartoesAgrupados
        )
    }

    private static func agruparPorCartao(
        _ lancamentos: [LancamentoModel]
    ) -> [CartaoNotificacao] {

        let agrupados = Dictionary(grouping: lancamentos) {
            $0.cartaoUuid
        }

        return agrupados.compactMap { (_, itens) in
            guard
                let primeiro = itens.first,
                let dataVencimento = primeiro.dataVencimentoCartao
            else { return nil }

            return CartaoNotificacao(
                cartaoId: primeiro.cartaoUuid,
                nomeCartao: primeiro.cartao?.nome ?? "Cartão",
                quantidade: itens.count,
                dataVencimento: dataVencimento,
                lancamentos: itens
            )
        }
    }
}

struct CartaoNotificacao: Identifiable {
    var id: String { cartaoId }
    let cartaoId: String
    let nomeCartao: String
    let quantidade: Int
    let dataVencimento: Date
    let lancamentos: [LancamentoModel] // NOVO: todos os lançamentos agrupados
}
