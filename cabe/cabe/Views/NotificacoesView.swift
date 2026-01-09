//
//  NotificacoesView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//
import SwiftUI
internal import Combine

struct NotificacoesView: View {

    @ObservedObject var vm: NotificacaoViewModel

    var body: some View {
        List {
            if !vm.vencemHoje.isEmpty || !vm.cartoesHoje.isEmpty {
                Section("Vence Hoje") {
                    ForEach(vm.vencemHoje) { lancamento in
                        LancamentoRow(
                            lancamento: lancamento,
                            mostrarPagamento: false,
                            mostrarValores: true
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                            Button() {
                                Task {
                                    await vm.marcarLancamentosComoLidos([lancamento])
                                }
                            } label: {
                                Label ("Lido", systemImage: "checklist")
                            }
                            .tint(.accentColor)
                        }
                    }
                    ForEach(vm.cartoesHoje) { cartao in
                        CartaoRowNotification(cartaoNotificacao: cartao)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                Button() {
                                    Task {
                                        await vm.marcarLancamentosComoLidos(cartao.lancamentos)
                                    }
                                } label: {
                                    Label ("Lido", systemImage: "checklist")
                                    
                                }
                                .tint(.accentColor)
                            }
                    }
                }
            
                if !vm.vencidos.isEmpty || !vm.cartoesVencidos.isEmpty {
                    Section("Vencidos") {
                        ForEach(vm.vencidos) { lancamento in
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,
                                mostrarValores: true
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                Button() {
                                    Task {
                                        await vm.marcarLancamentosComoLidos([lancamento])
                                    }
                                } label: {
                                    Label ("Lido", systemImage: "checklist")
                                    
                                }
                                .tint(.accentColor)
                            }
                        }
                        ForEach(vm.cartoesVencidos) { cartao in
                            CartaoRowNotification(cartaoNotificacao: cartao)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                    Button() {
                                        Task {
                                            await vm.marcarLancamentosComoLidos(cartao.lancamentos)
                                        }
                                    } label: {
                                        Label ("Lido", systemImage: "checklist")
                                        
                                    }
                                    .tint(.accentColor)
                                }
                        }
                    }
                }

            }
        }
        .navigationTitle("Notificações")
        .listStyle(.insetGrouped)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Notificações")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await vm.marcarLancamentosComoLidos(
                            vm.vencidos +
                            vm.vencemHoje +
                            vm.cartoesVencidos.flatMap(\.lancamentos) +
                            vm.cartoesHoje.flatMap( \.lancamentos)
                        )
                    }
                } label: {
                    Image(systemName: "checklist")
                }
            }
        }

    }
}

struct CartaoRowNotification: View {
    let cartaoNotificacao: CartaoNotificacao
   
    private var totalDoCartao: Decimal {
        cartaoNotificacao.lancamentos.reduce(0) { partialResult, lancamento in
            partialResult + lancamento.valor
        }
    }

    var body: some View {
        HStack (spacing: 12) {
            Image(
                cartaoNotificacao.lancamentos.first?.cartao?.operadoraEnum.imageName ?? ""
            )
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(cartaoNotificacao.nomeCartao)
                    .font(.body)
                    .foregroundColor(.primary)
                Text("\(cartaoNotificacao.quantidade) lançamento(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(formatarValor(totalDoCartao))")
                .foregroundColor(.secondary)
        }
    }
    
    private func formatarValor(_ valor: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = cartaoNotificacao.lancamentos.first?.cartao?.conta?.currencyCode ?? "BRL"
        return formatter.string(from: valor as NSDecimalNumber) ?? "\(valor)"
    }
}
