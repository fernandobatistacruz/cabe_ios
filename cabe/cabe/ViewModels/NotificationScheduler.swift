//
//  NotificationScheduler.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/01/26.
//


import Foundation
import UserNotifications

final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    private let prefix = "cartao-vencimento"

    // MARK: - Agendar

    func agendar(notificacoes: [CartaoNotificacao]) {

        let center = UNUserNotificationCenter.current()

        for item in notificacoes {

            var components = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: item.dataVencimento
            )
            components.hour = 9
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let content = UNMutableNotificationContent()
            content.title = "Fatura vence hoje"
            content.body = "\(item.nomeCartao) • \(item.quantidade) lançamentos"
            content.sound = .default

            // 🔑 usado para deep link
            content.userInfo = [
                "destino": "notificacoes"
            ]

            let identifier = "\(prefix)-\(item.cartaoId)-\(components.month ?? 0)"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    // MARK: - Cancelar tudo

    func cancelarTodas() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
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


