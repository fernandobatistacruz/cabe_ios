//
//  FaturaListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 16/01/26.
//

import SwiftUI

struct FaturaListView: View {
    
    @ObservedObject var viewModel: LancamentoListViewModel
    @State private var showCalendar = false
       
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: viewModel.anoAtual,
                month: viewModel.mesAtual,
                day: 1
            )
        ) ?? Date()
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(lancamentosAgrupados, id: \.date) { section in
                    Section {
                        ForEach(section.items) { item in
                            if case .cartaoAgrupado(let cartao, let total, let lancamentos) = item {
                                NavigationLink {
                                    FaturaDetalharView(
                                        viewModel: viewModel,
                                        cartao: cartao,                                        
                                        total: total,
                                        vencimento: section.date
                                    )
                                } label: {
                                    LancamentoCartaoRow(
                                        cartao: cartao,
                                        lancamentos: lancamentos,
                                        total: total
                                    )
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            Task {
                                                await viewModel.togglePago(lancamentos)
                                            }
                                        } label: {
                                            let temPendentes = lancamentos.contains { !$0.pago }
                                            Label(
                                                temPendentes
                                                    ? String(localized: "Pago")
                                                    : String(localized: "Não Pago"),
                                                systemImage: temPendentes
                                                    ? "checklist.checked"
                                                    : "checklist.unchecked"
                                            )
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
                    } header: {
                        Text(section.date, format: .dateTime.day().month(.wide))
                    }
                }
            }
            .overlay{
                if lancamentosAgrupados.isEmpty {
                    Group {
                        Text("Nenhuma Fatura")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }                
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Faturas")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCalendar = true
                } label: {
                    Text(selectedDate, format: .dateTime.year())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink {
                        CartaoListView()
                    } label: {
                        Label("Gerenciar Cartões", systemImage: "creditcard")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showCalendar) {
            ZoomCalendarioView(
                dataInicial: selectedDate,
                onConfirm: { dataSelecionada in
                    viewModel.selecionar(data: dataSelecionada)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    var lancamentosAgrupados: [(date: Date, items: [LancamentoItem])] {

        let porData = Dictionary(grouping: viewModel.lancamentos) {
            Calendar.current.startOfDay(for: $0.dataAgrupamento)
        }

        let resultado = porData.compactMap { (date, lancamentosDoDia) -> (Date, [LancamentoItem])? in

            let comCartao = lancamentosDoDia.filter { $0.cartao != nil }

            guard !comCartao.isEmpty else { return nil }

            let porCartao = Dictionary(grouping: comCartao) {
                $0.cartao!.id!
            }

            let itensCartao = porCartao.map { (_, lancamentos) in
                let cartao = lancamentos.first!.cartao!
                let total = lancamentos.reduce(.zero) { $0 + $1.valorComSinal }

                return LancamentoItem.cartaoAgrupado(
                    cartao: cartao,
                    total: total,
                    lancamentos: lancamentos
                )
            }

            return (date: date, items: itensCartao)
        }

        return resultado.sorted { $0.0 > $1.0 }
    }
}
