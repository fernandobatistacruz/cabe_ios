//
//  NotificationScheduler.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/01/26.
//

import UserNotifications

// NotificationService.swift

final class NotificationService {

    private let repository: LancamentoRepository
    private let scheduler = NotificationScheduler.shared

    init(repository: LancamentoRepository = .init()) {
        self.repository = repository
    }

    func atualizarNotificacoes() async {
        guard AppStorageWrapper.notificacoesAtivas else {
            scheduler.atualizar(
                payload: .init(lancamentosSimples: [], cartoes: []),
                notificacoesAtivas: false
            )
            return
        }

        do {
            let lancamentos = try await repository
                .listarLancamentosFuturosParaAgendar()

            let payload = NotificacaoFactory
                .gerar(lancamentos: lancamentos)

            scheduler.atualizar(
                payload: payload,
                notificacoesAtivas: true
            )

        } catch {
            print("Erro ao atualizar notificações:", error)
        }
    }
}
