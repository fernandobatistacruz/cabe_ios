//
//  NotificacoesLancamentosView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 17/12/25.
//

import SwiftUI
internal import Combine

struct NotificacoesView: View {
    @ObservedObject var vm: NotificacoesViewModel

    var body: some View {
        List {

            if !vm.venceHoje.isEmpty {
                Section(String(localized: "Vence Hoje")) {
                    ForEach(vm.venceHoje) { item in
                        NotificacaoRow(item: item)
                    }
                }
            }

            if !vm.vencidos.isEmpty {
                Section(String(localized: "Vencidos")){
                    ForEach(vm.vencidos) { item in
                        NotificacaoRow(item: item)
                    }
                }
            }
        }
        .navigationTitle("Notificações")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct NotificacaoRow: View {
    let item: Lancamento

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.titulo)
                    .font(.subheadline)

                Text(item.vencimento, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.valor, format: .currency(code: "BRL"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
    }

    private var statusColor: Color {
        item.vencimento.isToday ? .orange : .red
    }
}



final class NotificacoesViewModel: ObservableObject {

    @Published var lancamentos: [Lancamento] = []

    init() {
        carregarMock()
    }

    private func carregarMock() {
        let hoje = Date()
        let calendar = Calendar.current
        
        lancamentos = [
            
            Lancamento(
                titulo: "Cartão Nubank",
                valor: 450.90,
                vencimento: hoje,
                icon: "creditcard"
            ),
            Lancamento(
                titulo: "Internet",
                valor: 119.90,
                vencimento: hoje,
                icon: "wifi"
            ),
            Lancamento(
                titulo: "Energia elétrica",
                valor: 210.35,
                vencimento: calendar.date(byAdding: .day, value: -2, to: hoje)!,
                icon: "bolt"
            ),
            Lancamento(
                titulo: "Aluguel",
                valor: 1800.00,
                vencimento: calendar.date(byAdding: .day, value: -5, to: hoje)!,
                icon: "building.2"
            )
        ]
        
    }

    var venceHoje: [Lancamento] {
        lancamentos.filter { $0.vencimento.isToday }
    }

    var vencidos: [Lancamento] {
        lancamentos.filter { $0.vencimento.isPast && !$0.vencimento.isToday }
    }

    var totalNotificacoes: Int {
        venceHoje.count + vencidos.count
    }
}


extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isPast: Bool {
        self < Calendar.current.startOfDay(for: Date())
    }
}

struct Lancamento: Identifiable {
    let id = UUID()
    let titulo: String
    let valor: Double
    let vencimento: Date
    let icon: String   // SF Symbol
}


#Preview {
    NavigationStack {
        NotificacoesView(
            vm: NotificacoesViewModel()
        )
    }
}
