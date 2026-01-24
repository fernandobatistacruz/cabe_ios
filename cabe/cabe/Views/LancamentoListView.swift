//
//  LancamentoListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import SwiftUI

struct LancamentoListView: View {
    
    @ObservedObject var viewModel: LancamentoListViewModel
    
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
    
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: viewModel.anoAtual,
                month: viewModel.mesAtual,
                day: 1
            )
        ) ?? Date()
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
                            switch item {

                            case .simples(let lancamento):
                                NavigationLink {
                                    LancamentoDetalheView(
                                        lancamento: lancamento,
                                        repository: viewModel.repository
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
                                    .swipeActions(edge: .leading,allowsFullSwipe: false) {
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
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        mostrarNovoLancamento = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
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
            Text(
                selectedDate
                    .formatted(.dateTime.month(.wide))
                    .capitalized
            )
        )
        .navigationBarTitleDisplayMode(.large)
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
                        Label("Transferência", systemImage: "arrow.left.arrow.right")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
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
                    viewModel.selecionar(data: dataSelecionada)
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
            ShareSheetView(activityItems: [item.url])
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
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
    }
    
    private func totalDaSection(_ items: [LancamentoItem]) -> Decimal {
        items.reduce(.zero) { parcial, item in
            switch item {
            case .simples(let lancamento):
                return parcial + lancamento.valorComSinal

            case .cartaoAgrupado(_, let total, _):
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
    
    var lancamentosAgrupados: [LancamentoSectionAcumulada] {

        let porData = Dictionary(grouping: lancamentosFiltrados) {
            Calendar.current.startOfDay(for: $0.dataAgrupamento)
        }

        // 1️⃣ monta as sections base
        let sectionsBase: [(date: Date, items: [LancamentoItem])] =
            porData.map { (date, lancamentosDoDia) in

                let itensSimples = lancamentosDoDia
                    .filter { $0.cartao == nil }
                    .map { LancamentoItem.simples($0) }

                let comCartao = lancamentosDoDia.filter { $0.cartao != nil }

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

                return (date: date, items: itensSimples + itensCartao)
            }

        // 2️⃣ ordena CRESCENTE para calcular o fluxo
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

        // 3️⃣ reordena para exibição (DECRESCENTE)
        return comSaldoCalculado.sorted { $0.date > $1.date }
    }
    
    private func excluir(_ lancamento: LancamentoModel) async {
        await viewModel.remover(id: lancamento.id ?? 0, uuid: lancamento.uuid)
    }
}

struct LancamentoCartaoRow: View {

    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]
    let total: Decimal
   
    private var temPendentes: Bool {
        lancamentos.contains { !$0.pago }
    }

    var body: some View {
        HStack(spacing: 12) {
        
            Circle()
                .fill(temPendentes ? .accentColor : Color.clear)
                .frame(width: 12, height: 12)
          
            Image(cartao.operadoraEnum.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        
            VStack(alignment: .leading, spacing: 2) {
                Text(cartao.nome)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text("Fatura")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(
                total,
                format: .currency(code: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode)
            )
            .foregroundColor(.secondary)
        }
    }
}

struct LancamentoRow: View {
    let lancamento: LancamentoModel   
    let mostrarPagamento: Bool
    let mostrarValores: Bool

    var body: some View {
        HStack(spacing: 12) {
            if (mostrarPagamento)  {
                Circle()
                    .fill(lancamento.pago ? Color.clear : .accentColor)
                    .frame(width: 12, height: 12)
            }
            let systemName: String = {
                if lancamento.transferencia {
                    return "arrow.left.arrow.right"
                } else {
                    return lancamento.categoria?.getIcone().systemName ?? "questionmark"
                }
            }()

            let color: Color = {
                if lancamento.transferencia {
                    return lancamento.tipo == Tipo.despesa.rawValue ? .red : .green
                } else {
                    return lancamento.categoria?.getCor().cor ?? .primary
                }
            }()

            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                HStack{
                    Text(lancamento.descricao)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.body)
                        .foregroundColor(.primary)
                    if lancamento.recorrente == TipoRecorrente.parcelado.rawValue {
                        Text(lancamento.parcelaMes)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if lancamento.recorrente == TipoRecorrente.mensal.rawValue ||
                       lancamento.recorrente == TipoRecorrente.quinzenal.rawValue ||
                       lancamento.recorrente == TipoRecorrente.semanal.rawValue
                    {
                        Image(systemName: "repeat")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                    
                let subtitleText: String = {
                    if lancamento.transferencia {
                        return lancamento.conta?.nome ?? ""
                    } else {
                        if lancamento.categoria?.isSub == true {
                            return lancamento.categoria?.nomeSubcategoria ?? ""
                        } else {
                            return lancamento.categoria?.nome ?? ""
                        }
                    }
                }()

                Text(subtitleText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            
            
            if(mostrarValores) {
                Text(
                    lancamento.valorComSinal,
                    format: .currency(
                        code: lancamento.currencyCode
                    )
                )
                .foregroundColor(.secondary)
            } else {
                Text("•••")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LancamentoSectionAcumulada {
    let date: Date
    let items: [LancamentoItem]
    let saldoAcumulado: Decimal
}
