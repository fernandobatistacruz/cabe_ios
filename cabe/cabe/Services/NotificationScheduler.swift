//
//  NotificationScheduler 2.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 15/01/26.
//


// NotificationScheduler.swift

import UserNotifications

final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    func atualizar(
        payload: NotificationPayload,
        notificacoesAtivas: Bool
    ) {
        let center = UNUserNotificationCenter.current()

        guard notificacoesAtivas else {
            center.removeAllPendingNotificationRequests()
            return
        }

        center.removeAllPendingNotificationRequests()

        agendarLancamentosSimples(payload.lancamentosSimples)
        agendarCartoes(payload.cartoes)
    }

    private func agendarLancamentosSimples(
        _ lancamentos: [LancamentoModel]
    ) {
        for lancamento in lancamentos {

            var components = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: lancamento.dataAgrupamento
            )
            components.hour = 9
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Vencimento hoje"
            content.body = lancamento.descricao
            content.sound = .default
            content.userInfo = ["destino": "notificacoes"]

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "lancamento-\(lancamento.uuid)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    private func agendarCartoes(
        _ cartoes: [CartaoNotificacao]
    ) {
        for cartao in cartoes {

            var components = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: cartao.dataVencimento
            )
            components.hour = 9
            components.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Fatura vence hoje"
            content.body = "\(cartao.nomeCartao) • \(cartao.quantidade) lançamentos"
            content.sound = .default
            content.userInfo = ["destino": "notificacoes"]

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "cartao-\(cartao.cartaoId)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }
}
