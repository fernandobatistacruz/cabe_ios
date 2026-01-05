//
//  NotificacaoViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/01/26.
//

import Foundation
internal import Combine

@MainActor
final class NotificacaoViewModel: ObservableObject {

    // Lançamentos simples
    @Published private(set) var vencidos: [LancamentoModel] = []
    @Published private(set) var vencemHoje: [LancamentoModel] = []

    // Cartões agrupados
    @Published private(set) var cartoesVencidos: [CartaoNotificacao] = []
    @Published private(set) var cartoesHoje: [CartaoNotificacao] = []

    var total: Int {
        vencidos.count + vencemHoje.count + cartoesVencidos.count + cartoesHoje.count
    }

    func atualizar(lancamentos: [LancamentoModel]) {
        let hoje = Calendar.current.startOfDay(for: Date())

        // 1. Lançamentos simples
        let lancamentosSimples = lancamentos.filter { $0.cartaoUuid.isEmpty }

        vencidos = lancamentosSimples.filter {
            !$0.pago && $0.dataAgrupamento < hoje
        }

        vencemHoje = lancamentosSimples.filter {
            !$0.pago && Calendar.current.isDate($0.dataAgrupamento, inSameDayAs: hoje)
        }

        // 2. Lançamentos de cartão, agrupados por cartão
        let lancamentosCartao = lancamentos.filter { !$0.cartaoUuid.isEmpty }

        cartoesVencidos = gerarNotificacoesPorCartao(
            lancamentos: lancamentosCartao.filter { $0.dataAgrupamento < hoje && !$0.pago }
        )

        cartoesHoje = gerarNotificacoesPorCartao(
            lancamentos: lancamentosCartao.filter { Calendar.current.isDate($0.dataAgrupamento, inSameDayAs: hoje) && !$0.pago }
        )
    }

    func mensagemNotificacao() -> String {
        let simples = "\(vencidos.count) vencidos • \(vencemHoje.count) hoje"
        let cartoes = "\(cartoesVencidos.count) cartões vencidos • \(cartoesHoje.count) hoje"

        let partes = [simples, cartoes].filter { !$0.hasPrefix("0") && !$0.contains("0 ") }
        return partes.joined(separator: " • ")
    }

    // MARK: - Cartões
    private func gerarNotificacoesPorCartao(lancamentos: [LancamentoModel]) -> [CartaoNotificacao] {

        let agrupados = Dictionary(grouping: lancamentos) { $0.cartaoUuid }

        return agrupados.compactMap { (_, itens) in
            guard let primeiro = itens.first,
                  let dataVencimento = primeiro.dataVencimentoCartao
            else { return nil }

            return CartaoNotificacao(
                cartaoId: primeiro.cartaoUuid,
                nomeCartao: primeiro.cartao?.nome ?? "Cartão",
                quantidade: itens.count,
                dataVencimento: dataVencimento
            )
        }
    }
}

