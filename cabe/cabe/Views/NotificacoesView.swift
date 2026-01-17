//
//  NotificacoesView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 06/01/26.
//
import SwiftUI
import Combine

struct NotificacoesView: View {
    @ObservedObject var vmLancaentos: LancamentoListViewModel
    @ObservedObject var vmNotificacao: NotificacaoViewModel

    @State private var showConfirmMarcarLidos = false

    var body: some View {
        List {
            if vmNotificacao.temVenceHoje {
                VenceHojeSection(
                    vmLancamentos: vmLancaentos,
                    vmNotificacao: vmNotificacao
                )
            }

            if vmNotificacao.temVencidos {
                VencidosSection(
                    vmLancamentos: vmLancaentos,
                    vmNotificacao: vmNotificacao
                )
            }
        }
        .navigationTitle("Notificações")
        .listStyle(.insetGrouped)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showConfirmMarcarLidos = true
                } label: {
                    Image(systemName: "checklist")
                }
            }
        }
        .confirmationDialog(
            "Marcar Tudo como Lido?",
            isPresented: $showConfirmMarcarLidos,
            titleVisibility: .visible
        ) {
            Button("Marcar Todos como Lidos", role: .destructive) {
                Task {
                    await vmNotificacao.marcarTodosComoLidos()
                }
            }

            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Essa ação não pode ser desfeita.")
        }
    }
}

private struct VenceHojeSection: View {
    let vmLancamentos: LancamentoListViewModel
    let vmNotificacao: NotificacaoViewModel

    var body: some View {
        Section("Vence Hoje") {
            ForEach(vmNotificacao.vencemHoje) { lancamento in
                NavigationLink {
                    LancamentoDetalheView(lancamento: lancamento)
                } label: {
                    LancamentoRow(
                        lancamento: lancamento,
                        mostrarPagamento: false,
                        mostrarValores: true
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            Task {
                                await vmNotificacao.marcarLancamentosComoLidos([lancamento])
                            }
                        } label: {
                            Label("Lido", systemImage: "checklist")
                        }
                        .tint(.accentColor)
                    }
                }
            }

            ForEach(vmNotificacao.cartoesVenceHoje) { cartao in
                NavigationLink {
                    CartaoFaturaView(
                        viewModel: vmLancamentos,
                        cartao: cartao.cartao,
                        lancamentos: cartao.lancamentos,
                        total: 0,
                        vencimento: cartao.dataVencimento
                    )
                } label: {
                    CartaoRowNotification(cartaoNotificacao: cartao)
                        .listRowInsets(
                            EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    await vmNotificacao.marcarLancamentosComoLidos(cartao.lancamentos)
                                }
                            } label: {
                                Label("Lido", systemImage: "checklist")
                            }
                            .tint(.accentColor)
                        }
                }
            }
        }
        .listRowInsets(
            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
    }
}

private struct VencidosSection: View {
    let vmLancamentos: LancamentoListViewModel
    let vmNotificacao: NotificacaoViewModel

    var body: some View {
        Section("Vencidos") {
            ForEach(vmNotificacao.vencidos) { lancamento in
                NavigationLink {
                    LancamentoDetalheView(lancamento: lancamento)
                } label: {
                    LancamentoRow(
                        lancamento: lancamento,
                        mostrarPagamento: false,
                        mostrarValores: true
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            Task {
                                await vmNotificacao.marcarLancamentosComoLidos([lancamento])
                            }
                        } label: {
                            Label("Lido", systemImage: "checklist")
                        }
                        .tint(.accentColor)
                    }
                }
            }

            ForEach(vmNotificacao.cartoesVencidos) { cartao in
                NavigationLink {
                    CartaoFaturaView(
                        viewModel: vmLancamentos,
                        cartao: cartao.cartao,
                        lancamentos: cartao.lancamentos,
                        total: 0,
                        vencimento: cartao.dataVencimento
                    )
                } label: {
                    CartaoRowNotification(cartaoNotificacao: cartao)
                        .listRowInsets(
                            EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    await vmNotificacao.marcarLancamentosComoLidos(cartao.lancamentos)
                                }
                            } label: {
                                Label("Lido", systemImage: "checklist")
                            }
                            .tint(.accentColor)
                        }
                }
            }
        }
        .listRowInsets(
            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
    }
}



/*
struct NotificacoesView: View {
    @ObservedObject var vmLancaentos: LancamentoListViewModel
    @ObservedObject var vmNotificacao: NotificacaoViewModel
    
    @State private var showConfirmMarcarLidos = false

    var body: some View {
        List {
            if !vmNotificacao.vencemHoje.isEmpty || !vmNotificacao.cartoesVenceHoje.isEmpty {
                Section("Vence Hoje") {
                    ForEach(vmNotificacao.vencemHoje) { lancamento in
                        NavigationLink {
                            LancamentoDetalheView(lancamento: lancamento)
                        } label: {
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,
                                mostrarValores: true
                            )
                            .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                Button() {
                                    Task {
                                        await vmNotificacao.marcarLancamentosComoLidos([lancamento])
                                    }
                                } label: {
                                    Label ("Lido", systemImage: "checklist")
                                }
                                .tint(.accentColor)
                            }
                        }
                    }
                    ForEach(vmNotificacao.cartoesVenceHoje) { cartao in
                        //TODO: Mostrar detalhada para cartão
                        NavigationLink {
                            CartaoFaturaView(
                                viewModel: vmLancaentos,
                                cartao: cartao,
                                lancamentos: cartao.lancamentos,
                                total: 0,
                                vencimento: cartao.dataVencimento
                            )
                        } label: {
                            CartaoRowNotification(cartaoNotificacao: cartao)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                    Button() {
                                        Task {
                                            await vmNotificacao.marcarLancamentosComoLidos(cartao.lancamentos)
                                        }
                                    } label: {
                                        Label ("Lido", systemImage: "checklist")
                                        
                                    }
                                    .tint(.accentColor)
                                }
                        }
                    }
                }
                .listRowInsets(
                    EdgeInsets(
                        top: 8,
                        leading: 16,
                        bottom: 8,
                        trailing: 16
                    )
                )
            }
            
            if !vmNotificacao.vencidos.isEmpty || !vmNotificacao.cartoesVencidos.isEmpty {
                Section("Vencidos") {
                    ForEach(vmNotificacao.vencidos) { lancamento in
                        NavigationLink {
                            LancamentoDetalheView(lancamento: lancamento)
                        } label: {
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,
                                mostrarValores: true
                            )
                            .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                Button() {
                                    Task {
                                        await vmNotificacao.marcarLancamentosComoLidos([lancamento])
                                    }
                                } label: {
                                    Label ("Lido", systemImage: "checklist")
                                    
                                }
                                .tint(.accentColor)
                            }
                        }
                    }
                    ForEach(vmNotificacao.cartoesVencidos) { cartao in
                        //TODO: Mostrar detalhada para cartão
                        NavigationLink {
                            CartaoFaturaView(
                                viewModel: vmLancaentos,
                                cartao: cartao,
                                lancamentos: cartao.lancamentos,
                                total: 0,
                                vencimento: cartao.dataVencimento
                            )
                        } label: {
                            CartaoRowNotification(cartaoNotificacao: cartao)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing,allowsFullSwipe: false) {
                                    Button() {
                                        Task {
                                            await vmNotificacao.marcarLancamentosComoLidos(cartao.lancamentos)
                                        }
                                    } label: {
                                        Label ("Lido", systemImage: "checklist")
                                        
                                    }
                                    .tint(.accentColor)
                                }
                        }
                    }
                    
                }
                .listRowInsets(
                    EdgeInsets(
                        top: 8,
                        leading: 16,
                        bottom: 8,
                        trailing: 16
                    )
                )
            }
        }
        .navigationTitle("Notificações")
        .listStyle(.insetGrouped)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Notificações")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showConfirmMarcarLidos = true
                } label: {
                    Image(systemName: "checklist")
                }
            }
        }
        .confirmationDialog(
            "Marcar Tudo como Lido?",
            isPresented: $showConfirmMarcarLidos,
            titleVisibility: .visible
        ) {
            Button("Marcar Todos como Lidos", role: .destructive) {
                Task {
                    await vmNotificacao.marcarTodosComoLidos()
                }
            }
            /*
            Button("Marcar Todos como Lidos", role: .destructive) {
                Task {
                    await vmNotificacao.marcarLancamentosComoLidos(
                        vmNotificacao.vencidos +
                        vmNotificacao.vencemHoje +
                        vmNotificacao.cartoesVencidos.flatMap(\.lancamentos) +
                        vmNotificacao.cartoesVenceHoje.flatMap(\.lancamentos)
                    )
                }
            }
             */

            Button("Cancelar", role: .cancel) { }

        } message: {
            Text("Essa ação não pode ser desfeita.")
        }

    }
}
 */

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
        formatter.currencyCode = cartaoNotificacao.lancamentos.first?.cartao?.conta?.currencyCode ?? "USD"
        return formatter.string(from: valor as NSDecimalNumber) ?? "\(valor)"
    }
}
