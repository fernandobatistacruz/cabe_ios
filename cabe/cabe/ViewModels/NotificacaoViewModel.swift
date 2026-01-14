//
//  NotificacaoViewModel.swift
//  cabe
//

import Foundation
import Combine

@MainActor
final class NotificacaoViewModel: ObservableObject {

    // MARK: - Lançamentos simples
    @Published private(set) var vencidos: [LancamentoModel] = []
    @Published private(set) var vencemHoje: [LancamentoModel] = []

    // MARK: - Cartões agrupados
    @Published private(set) var cartoesVencidos: [CartaoNotificacao] = []
    @Published private(set) var cartoesVenceHoje: [CartaoNotificacao] = []

    // MARK: - Total de notificações não lidas
    var total: Int {
        vencidos.count + vencemHoje.count + cartoesVencidos.count + cartoesVenceHoje.count
    }

    // MARK: - Atualiza a ViewModel com lançamentos
    func atualizar(lancamentos: [LancamentoModel]) {
        let hoje = Calendar.current.startOfDay(for: Date())

        // 1️⃣ Filtra apenas não lidos
        let naoLidos = lancamentos.filter { !$0.notificacaoLida }

        // 2️⃣ Lançamentos simples (sem cartão)
        let lancamentosSimples = naoLidos.filter { $0.cartaoUuid.isEmpty }

        vencidos = lancamentosSimples.filter {
            !$0.pago && $0.dataAgrupamento < hoje
        }

        vencemHoje = lancamentosSimples.filter {
            !$0.pago && Calendar.current.isDate($0.dataAgrupamento, inSameDayAs: hoje)
        }

        // 3️⃣ Lançamentos de cartão, agrupados por cartão
        let lancamentosCartao = naoLidos.filter { !$0.cartaoUuid.isEmpty }

        cartoesVencidos = gerarNotificacoesPorCartao(
            lancamentos: lancamentosCartao.filter { $0.dataAgrupamento < hoje && !$0.pago }
        )

        cartoesVenceHoje = gerarNotificacoesPorCartao(
            lancamentos: lancamentosCartao.filter { Calendar.current.isDate($0.dataAgrupamento, inSameDayAs: hoje) && !$0.pago }
        )
    }

    // MARK: - Mensagem para notificação do sistema
    func mensagemNotificacao() -> String {
        let simples = "\(vencidos.count) vencidos • \(vencemHoje.count) hoje"
        let cartoes = "\(cartoesVencidos.count) cartões vencidos • \(cartoesVenceHoje.count) hoje"

        let partes = [simples, cartoes].filter { !$0.hasPrefix("0") && !$0.contains("0 ") }
        return partes.joined(separator: " • ")
    }

    // MARK: - Marcar notificação como lida
    func marcarLancamentosComoLidos(_ lancamentos: [LancamentoModel]) async {
        let naoLidos = lancamentos.filter { !$0.notificacaoLida }
        guard !naoLidos.isEmpty else { return }

        let atualizados = naoLidos.map { lancamento -> LancamentoModel in
            var l = lancamento
            l.notificacaoLida = true
            return l
        }

        do {
            let repository = LancamentoRepository()
            for lancamento in atualizados {
                try await repository.editar(lancamento)
            }

            // Atualiza a UI
            let todos = vencidos + vencemHoje + cartoesVencidos.flatMap { $0.lancamentos } + cartoesVenceHoje.flatMap { $0.lancamentos }
            atualizar(lancamentos: todos)
        } catch {
            print("Erro ao marcar notificações como lidas:", error)
        }
    }

    // MARK: - Gerar notificações agrupadas por cartão
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
                dataVencimento: dataVencimento,
                lancamentos: itens
            )
        }
    }
}

