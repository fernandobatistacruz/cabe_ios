//
//  LancamentoListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import SwiftUI

struct LancamentoListView: View {
    
    @ObservedObject var viewModel: LancamentoListViewModel
    @State var filtroSelecionado: FiltroLancamento = .todos
    @State var mostrarZoomCalendario: Bool = true
    @State private var searchText = ""
    @State private var mostrarNovoLancamento = false
    @State private var lancamentoParaExcluir: LancamentoModel?
    @State private var showCalendar = false
    @State private var mostrarDialogExclusao = false
    @EnvironmentObject var sub: SubscriptionManager
    @State private var showingPaywall = false
    @State private var mostrarTransferencia = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    @State private var filtroTipo: FiltroTipo = .todos
    @State private var selectedDate: Date = Date()
    @State private var direcao: Edge = .trailing
    
    private var filtroAtivo: Bool {
        filtroSelecionado != .todos || filtroTipo != .todos
    }
    
    var lancamentosFiltrados: [LancamentoModel] {
        var resultado = searchText.isEmpty
        ? viewModel.lancamentos
        : viewModel.lancamentos.filter {
            $0.descricao.localizedCaseInsensitiveContains(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        switch filtroTipo {
        case .todos:
            break
        case .receita:
            resultado = resultado.filter { $0.tipo == Tipo.receita.rawValue && $0.transferencia == false }
            break
        case .despesa:
            resultado = resultado.filter { $0.tipo == Tipo.despesa.rawValue && $0.transferencia == false}
            break
        }
        
        switch filtroSelecionado {
        case .todos:
            break
            
        case .recorrentes:
            resultado = resultado.filter {
                $0.tipoRecorrente == .semanal ||
                $0.tipoRecorrente == .quinzenal ||
                $0.tipoRecorrente == .mensal
            }
            
        case .pagos:
            resultado = resultado.filter {
                $0.pago == true
            }
            
        case .naoPagos:
            resultado = resultado.filter {
                $0.pago == false
            }
            
        case .parcelados:
            resultado = resultado.filter {
                $0.tipoRecorrente == .parcelado
            }
        }
            
        return resultado
    }
    
    var body: some View {
        List {
            ForEach(lancamentosAgrupados, id: \.date) { section in
                Section {
                    ForEach(section.items) { item in
                        switch item {
                            
                        case .simples(let lancamento):
                            NavigationLink {
                                LancamentoDetalheView(
                                    lancamento: lancamento,
                                    vmLancamentos: viewModel
                                )
                            } label: {
                                LancamentoRow(
                                    lancamento: lancamento,
                                    mostrarPagamento: true,
                                    mostrarValores: true
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        lancamentoParaExcluir = lancamento
                                        mostrarDialogExclusao = true
                                    } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button() {
                                        Task{
                                            await viewModel.togglePago([lancamento])
                                        }
                                    } label: {
                                        Label(lancamento.pago ? String(localized: "Não Pago") : String(localized: "Pago"), systemImage: lancamento.pago ? "checklist.unchecked" : "checklist")
                                            .tint(.accentColor)
                                        
                                    }
                                }
                            }
                            
                        case .cartaoAgrupado(let cartao, let total, let lancamentos):
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
                                .swipeActions(edge: .leading,allowsFullSwipe: false) {
                                    Button() {
                                        Task{
                                            await viewModel.togglePago(lancamentos)
                                        }
                                    } label: {
                                        var temPendentes: Bool {
                                            lancamentos.contains { !$0.pago }
                                        }
                                        Label(
                                            temPendentes ? String(
                                                localized: "Pago"
                                            ): String(localized: "Não Pago"),
                                            systemImage: temPendentes ?
                                            "checklist.checked" : "checklist.unchecked"
                                        )
                                    }.tint(.accentColor)
                                }
                            }
                        }
                    }
                    .listRowInsets(
                        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                    )
                    
                } header: {
                    HStack {
                        Text(section.date, format: .dateTime.day().month(.wide))
                        
                        Spacer()
                        
                        Text(
                            section.saldoAcumulado,
                            format: .currency(
                                code: viewModel.lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                            )
                        )
                        .font(.subheadline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
        .background(Color(.systemGroupedBackground))
        .scrollContentBackground(.hidden)
        .contentShape(Rectangle())
        .navigationTitle(
            Text(
                selectedDate
                    .formatted(.dateTime.month(.wide))
                    .capitalized
            )
        )
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Buscar")
        .onAppear {
            selectedDate = Calendar.current.date(
                from: DateComponents(
                    year: viewModel.anoAtual,
                    month: viewModel.mesAtual,
                    day: 1
                )
            ) ?? Date()
        }
        .toolbar {
            if mostrarZoomCalendario {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCalendar = true
                    } label: {
                        Text(selectedDate, format: .dateTime.year())
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Section {
                        ForEach(FiltroTipo.allCases) { filtro in
                            Button {
                                filtroTipo = filtro
                            } label: {
                                HStack {
                                    Text(filtro.titulo)
                                    
                                    Spacer()
                                    
                                    if filtroTipo == filtro {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        ForEach(FiltroLancamento.allCases) { filtro in
                            Button {
                                filtroSelecionado = filtro
                            } label: {
                                HStack {
                                    Text(filtro.titulo)
                                    
                                    Spacer()
                                    
                                    if filtroSelecionado == filtro {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: filtroAtivo
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease"
                    )
                    .symbolRenderingMode(filtroAtivo ? .palette : .monochrome)
                    .foregroundStyle(
                        filtroAtivo
                        ? Color.white
                        : {
                            if #available(iOS 26, *) {
                                return Color.primary
                            } else {
                                return Color.accentColor
                            }
                        }(),
                        Color.accentColor
                    )
                }
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
                        Label("Transferência", systemImage: "arrow.left.arrow.right")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarNovoLancamento = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog(
            "Excluir Lançamento?",
            isPresented: $mostrarDialogExclusao,
            titleVisibility: .visible
        ) {
            if let lancamento = lancamentoParaExcluir {
                
                if lancamento.tipoRecorrente == .nunca {
                    Button("Confirmar Exclusão", role: .destructive) {
                        Task { await viewModel.removerTodosRecorrentes(lancamento) }
                    }
                } else {
                    Button("Excluir Somente Este", role: .destructive) {
                        Task { await viewModel.removerSomenteEste(lancamento)}
                    }
                    
                    Button("Excluir Este e os Próximos", role: .destructive) {
                        Task { await viewModel.removerEsteEProximos(lancamento) }
                    }
                    
                    Button("Excluir Todos", role: .destructive) {
                        Task { await viewModel.removerTodosRecorrentes(lancamento) }
                    }
                }
            }
        }
        message: {
            Text("Essa ação não poderá ser desfeita.")
        }
        .sheet(isPresented: $mostrarNovoLancamento) {
            NovoLancamentoView(repository: viewModel.repository)
        }
        .sheet(isPresented: $showCalendar) {
            ZoomCalendarioView(
                dataInicial: selectedDate,
                onConfirm: { dataSelecionada in
                    selectedDate = dataSelecionada
                    showCalendar = false
                    viewModel.selecionar(data: selectedDate)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
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
            
            let mes = selectedDate.formatted(.dateTime.month(.wide)).capitalized
            
            ShareSheetView(
                message: String(localized: "Lançamentos de \(mes)/\(String(viewModel.anoAtual)) extraído do Cabe"),
                subject: String(localized: "Lançamentos de \(mes))/\(String(viewModel.anoAtual)) extraído do Cabe"),
                fileURL: item.url
            )
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
            if lancamentosFiltrados.isEmpty {
                Group {
                    Text("Nenhum Lançamento")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }   
    
    private func totalDaSection(_ items: [LancamentoItem]) -> Decimal {
        items.reduce(.zero) { parcial, item in
            switch item {
            case .simples(let lancamento):
                return parcial + lancamento.valorComSinalDividido

            case .cartaoAgrupado(_, _, let lancamentos):
                let total = lancamentos.reduce(.zero) { $0 + $1.valorComSinalDividido }
                return parcial + total
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
                    .locale(Locale.current)
            )
            
            let url = try await ExportarLancamentos.export(
                lancamentos: viewModel.lancamentos,
                fileName: String(localized: "lancamentos_\(mesPorExtenso).csv")
            )

            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }
    
    var lancamentosAgrupados: [LancamentoSectionAcumulada] {

        let porData = Dictionary(grouping: lancamentosFiltrados) {
            Calendar.current.startOfDay(for: $0.dataVencimento)
        }
       
        let sectionsBase: [(date: Date, items: [LancamentoItem])] =
            porData.map { (date, lancamentosDoDia) in

                let itensSimples = lancamentosDoDia
                    .filter { $0.cartao == nil }
                    .map { LancamentoItem.simples($0) }

                let comCartao = lancamentosDoDia.filter { $0.cartao != nil }

                let porCartao = Dictionary(grouping: comCartao) {
                    $0.cartao!.id!
                }

                let itensCartao = porCartao
                    .values
                    .sorted { lhs, rhs in
                        lhs.first!.cartao!.nome < rhs.first!.cartao!.nome
                    }
                    .map { lancamentos in
                        let cartao = lancamentos.first!.cartao!
                        let total = lancamentos.reduce(.zero) { $0 + $1.valorComSinal }
                        
                        return LancamentoItem.cartaoAgrupado(
                            cartao: cartao,
                            total: total,
                            lancamentos: lancamentos
                        )
                    }
                
                return (date: date, items: itensSimples + itensCartao)
            }
      
        let ordenadasParaCalculo = sectionsBase.sorted { $0.date < $1.date }

        var saldo: Decimal = .zero

        let comSaldoCalculado: [LancamentoSectionAcumulada] =
            ordenadasParaCalculo.map { section in
                let totalDoDia = totalDaSection(section.items)
                saldo += totalDoDia

                return LancamentoSectionAcumulada(
                    date: section.date,
                    items: section.items,
                    saldoAcumulado: saldo
                )
            }
      
        return comSaldoCalculado.sorted { $0.date > $1.date }
    }
    
    private func excluir(_ lancamento: LancamentoModel) async {
        await viewModel.remover(id: lancamento.id ?? 0, uuid: lancamento.uuid)
    }
}

struct LancamentoSectionAcumulada {
    let date: Date
    let items: [LancamentoItem]
    let saldoAcumulado: Decimal
}

