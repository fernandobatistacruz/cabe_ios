//
//  FaturaListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 16/01/26.
//

import SwiftUI

struct FaturaListView: View {
    
    @State private var searchText = ""
    @State private var mostrarNovoLancamento = false
    @State private var lancamentoParaExcluir: LancamentoModel?
    @StateObject private var viewModel: LancamentoListViewModel
    @State private var showCalendar = false
    @State private var mostrarDialogExclusao = false
    @EnvironmentObject var sub: SubscriptionManager
    @State private var showingPaywall = false
    @State private var mostrarTransferencia = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: viewModel.anoAtual,
                month: viewModel.mesAtual,
                day: 1
            )
        ) ?? Date()
    }
    
    init() {
        let repository = LancamentoRepository()
        let mesAtual = Calendar.current.component(.month, from: Date())
        let anoAtual = Calendar.current.component(.year, from: Date())
        
        _viewModel = StateObject(
            wrappedValue: LancamentoListViewModel(
                repository: repository,
                mes: mesAtual,
                ano: anoAtual
            )
        )
    }
    
    var lancamentosFiltrados: [LancamentoModel] {
        let texto = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return viewModel.lancamentos }
        
        return viewModel.lancamentos.filter {
            $0.descricao.localizedCaseInsensitiveContains(texto)
        }
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(lancamentosAgrupados, id: \.date) { section in
                    Section {
                        ForEach(section.items) { item in
                            if case .cartaoAgrupado(let cartao, let total, let lancamentos) = item {
                                NavigationLink {
                                    CartaoFaturaView(
                                        viewModel: viewModel,
                                        cartao: cartao,
                                        lancamentos: lancamentos,
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
            .listStyle(.insetGrouped)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        mostrarNovoLancamento = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(FloatingButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(
            Text(selectedDate, format: .dateTime.month(.wide))
        )
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $searchText, prompt: "Buscar")
        .toolbar {
            
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCalendar = true
                } label: {
                    //Image(systemName: "chevron.left")
                    Text(selectedDate, format: .dateTime.year())
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if sub.isSubscribed {
                            Task {
                                await exportarCSV()
                            }
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("Exportar", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                   
                    Divider()
                   
                    Button {
                        mostrarTransferencia = true
                    } label: {
                        Label("Transferência entre Contas", systemImage: "arrow.left.arrow.right")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .confirmationDialog(
            "Excluir lançamento?",
            isPresented: $mostrarDialogExclusao,
            titleVisibility: .visible
        ) {
            if let lancamento = lancamentoParaExcluir {
                
                if lancamento.tipoRecorrente == .nunca {
                    Button("Confirmar exclusão", role: .destructive) {
                        Task { await viewModel.removerTodosRecorrentes(lancamento) }
                    }
                } else {
                    Button("Excluir somente este", role: .destructive) {
                        Task { await viewModel.removerSomenteEste(lancamento)}
                    }
                    
                    Button("Excluir este e os próximos", role: .destructive) {
                        Task { await viewModel.removerEsteEProximos(lancamento) }
                    }
                    
                    Button("Excluir todos", role: .destructive) {
                        Task { await viewModel.removerTodosRecorrentes(lancamento) }
                    }
                }
            }
        }
        message: {
            Text("Essa ação não poderá ser desfeita.")
        }
        .sheet(isPresented: $mostrarNovoLancamento) {
            NovoLancamentoView()
        }
        .sheet(isPresented: $showCalendar) {
            ZoomCalendarioView(
                dataInicial: selectedDate,
                onConfirm: { dataSelecionada in
                    viewModel.selecionar(data: dataSelecionada)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .sheet(isPresented: $mostrarTransferencia) {
            NavigationStack {
                TransferenciaView()
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.url])
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                }
            }
        }
    }
        
    private func exportarCSV() async {
        guard !isExporting else { return }

        isExporting = true

        defer { isExporting = false }

        do {
            let mesPorExtenso = selectedDate.formatted(
                .dateTime
                    .month(.wide)
                    .locale(Locale(identifier: "pt_BR"))
            )
            
            let url = try await ExportarLancamentos.export(
                lancamentos: viewModel.lancamentos,
                fileName: "lancamentos_\(mesPorExtenso).csv"
            )

            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }
    
    var lancamentosAgrupados: [(date: Date, items: [LancamentoItem])] {

        let porData = Dictionary(grouping: lancamentosFiltrados) {
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
    
    
    private func excluir(_ lancamento: LancamentoModel) async {
        await viewModel.remover(id: lancamento.id ?? 0, uuid: lancamento.uuid)
    }
}
