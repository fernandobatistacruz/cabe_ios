//
//  ConsumoDetalhadoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/01/26.
//

import SwiftUI

enum PeriodoConsumo: CaseIterable, Identifiable {
    case mes
    case ano

    var id: Self { self }
}

struct ConsumoDetalhadoView: View {

    @ObservedObject var vm: LancamentoListViewModel
    @State private var yearlyItems: [CategoriaResumo] = []
    @State private var periodo: PeriodoConsumo = .mes
    @State private var loadingYear = false
    @State private var yearlyLancamentos: [LancamentoModel] = []
    @State private var showCalendar = false
    @State private var selectedDate: Date = Date()
    
    private var isEmpty: Bool {
        items.isEmpty
    }
    
    private var currentItems: [CategoriaResumo] {
        periodo == .mes ? items : yearlyItems
    }
    
    private var currentLancamentos: [LancamentoModel] {
        periodo == .mes ? vm.lancamentos : yearlyLancamentos
    }
    
    private func tituloPeriodo(_ periodo: PeriodoConsumo) -> String {

        switch periodo {
        case .mes:
            return selectedDate
                .formatted(.dateTime.month(.wide))
                .capitalized

        case .ano:
            return selectedDate.formatted(.dateTime.year())
        }
    }
    
    private var items: [CategoriaResumo] {
        vm.gastosPorCategoriaDetalhado
    }

    var body: some View {
        ZStack {
            if isEmpty {
                emptyState
            } else {
                content
            }
        }
        .onAppear {
            selectedDate = Calendar.current.date(
                from: DateComponents(
                    year: vm.anoAtual,
                    month: vm.mesAtual,
                    day: 1
                )
            ) ?? Date()
        }
        .task(
            id: "\(periodo)-\(Calendar.current.component(.year, from: selectedDate))"
        ) {

            guard periodo == .ano else { return }

            loadingYear = true

            do {
                let ano = Calendar.current.component(.year, from: selectedDate)

                let lancamentos = try await LancamentoRepository()
                    .listarLancamentosDoAno(ano: ano)

                yearlyLancamentos = lancamentos
                yearlyItems = gastosPorCategoriaDetalhado(lancamentos)

            } catch {
                print("Erro ao buscar lançamentos do ano:", error)
                yearlyLancamentos = []
                yearlyItems = []
            }

            loadingYear = false
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Consumo")
        .toolbar(.hidden, for: .tabBar)
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCalendar = true
                } label: {
                    Text(selectedDate, format: .dateTime.year())
                }
            }
        }
        .sheet(isPresented: $showCalendar) {
            ZoomCalendarioView(
                dataInicial: selectedDate,
                onConfirm: { dataSelecionada in
                    selectedDate = dataSelecionada
                    showCalendar = false
                    vm.selecionar(data: selectedDate)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                VStack(spacing: 8) {

                    Picker("", selection: $periodo) {
                        ForEach(PeriodoConsumo.allCases) { p in
                            Text(tituloPeriodo(p)).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
               
                VStack {
                    DonutChartView(
                        items: currentItems,
                        lineWidth: 26,
                        size: 180,
                        detalhar: true,
                        currencyCode: vm.lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
               
                VStack(alignment: .leading, spacing: 12) {

                    Text("Detalhamento")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        ForEach(Array(currentItems.enumerated()), id: \.offset) { index, item in

                            if item.categoriaID >= 0 {
                                NavigationLink {
                                    LancamentosPorCategoriaView(
                                        vm: vm,
                                        lancamentos: currentLancamentos,
                                        categoriaID: item.categoriaID,
                                        categoriaNome: item.nome
                                    )
                                } label: {
                                    ConsumoRow(item: item, mostraChevron: true)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ConsumoRow(item: item, mostraChevron: false)
                            }

                            if index < currentItems.count - 1 {
                                Divider()
                                    .padding(.leading, 24)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
            .padding()
        }
    }

    private func gastosPorCategoriaDetalhado (_ lancamentos: [LancamentoModel]) -> [CategoriaResumo] {

        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            $0.transferencia == false
        }

        // 🔑 NORMALIZA antes de agrupar
        let normalizados = despesas.map { lancamento -> (id: Int64, nome: String, cor: Color, valor: Double) in
            let info = categoriaPrincipalInfo(from: lancamento.categoria)
            
            let valorDecimal = lancamento.dividido
                ? lancamento.valor / 2
                : lancamento.valor

            let valor = NSDecimalNumber(decimal: valorDecimal).doubleValue

            return (
                id: info.id,
                nome: info.nome,
                cor: info.cor,
                valor: valor
            )
        }

        // 🔑 agora sim agrupa corretamente
        let agrupado = Dictionary(grouping: normalizados, by: \.id)

        let totaisBase = agrupado.map { (_, itens) in
            (
                categoriaID: itens.first!.id,
                nome: itens.first!.nome,
                valor: itens.reduce(0) { $0 + $1.valor },
                cor: itens.first!.cor
            )
        }

        let totalGeral = totaisBase.reduce(0) { $0 + $1.valor }
        guard totalGeral > 0 else { return [] }

        return totaisBase
            .sorted { $0.valor > $1.valor }
            .map {
                CategoriaResumo(
                    categoriaID: $0.categoriaID,
                    nome: $0.nome,
                    valor: $0.valor,
                    percentual: ($0.valor / totalGeral) * 100,
                    cor: $0.cor,
                    currencyCode: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            }
    }

    private func categoriaPrincipalInfo(
        from categoria: CategoriaModel?
    ) -> (id: Int64, nome: String, cor: Color) {
        if let categoria, categoria.isSub, let paiID = categoria.pai {
            return (
                id: paiID,
                nome: categoria.nome,
                cor: categoria.getCor().cor
            )
        }

        return (
            id: categoria?.id ?? 0,
            nome: categoria?.nome ?? "",
            cor: categoria?.getCor().cor ?? .gray
        )
    }
        
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("Nenhum Consumo")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ConsumoRow: View {

    let item: CategoriaResumo
    let mostraChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
           
            Circle()
                .fill(item.cor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.nome)
                    .foregroundStyle(.primary)

                Text(item.valorFormatado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.0f%%", item.percentual))               
                .foregroundStyle(.secondary)

            if mostraChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .contentShape(Rectangle()) // melhora o toque
    }
}

struct LancamentosPorCategoriaView: View {
    
    @ObservedObject var vm: LancamentoListViewModel
    let lancamentos: [LancamentoModel]
    let categoriaID: Int64
    let categoriaNome: String
    

    // MARK: - Estado

    @State private var expandedCategorias: Set<Int64>
    @State private var expandedSubs: Set<Int64> = []

    // MARK: - Init (categoria já inicia aberta)

    init(
        vm: LancamentoListViewModel,
        lancamentos: [LancamentoModel],
        categoriaID: Int64,
        categoriaNome: String
    ) {
        self.vm = vm
        self.lancamentos = lancamentos
        self.categoriaID = categoriaID
        self.categoriaNome = categoriaNome
        

        _expandedCategorias = State(initialValue: [categoriaID])
    }

    // MARK: - Filtros

    private var lancamentosCategoriaPrincipal: [LancamentoModel] {
        lancamentos.filter {
            $0.categoriaID == categoriaID &&
            $0.tipo == Tipo.despesa.rawValue
        }
    }

    private var lancamentosPorSub: [Int64: [LancamentoModel]] {
        Dictionary(
            grouping: lancamentos.filter {
                $0.categoria?.pai == categoriaID &&
                $0.tipo == Tipo.despesa.rawValue
            },
            by: { $0.categoriaID }
        )
    }

    // MARK: - Totais

    private func total(_ itens: [LancamentoModel]) -> Decimal {
        itens.reduce(0) { $0 + $1.valorParaSaldo }
    }

    /// total consolidado (principal + subs)
    private var totalCategoriaCompleta: Decimal {
        total(lancamentosCategoriaPrincipal) +
        total(lancamentosPorSub.values.flatMap { $0 })
    }

    // MARK: - BODY

    var body: some View {

        List {

            categoriaRow(
                id: categoriaID,
                nome: categoriaNome,
                total: totalCategoriaCompleta,
                expanded: expandedCategorias.contains(categoriaID)
            )

            if expandedCategorias.contains(categoriaID) {

                // lançamentos diretos
                ForEach(lancamentosCategoriaPrincipal) { lancamento in
                    lancamentoRow(lancamento)
                        .padding(.leading, 24)
                }

                ForEach(lancamentosPorSub.keys.sorted(), id: \.self) { subID in

                    let itens = lancamentosPorSub[subID] ?? []

                    let nomeSub =
                        itens.first?.categoria?.nomeSubcategoria
                        ?? "Subcategoria"

                    subcategoriaRow(
                        id: subID,
                        nome: nomeSub,
                        total: total(itens),
                        expanded: expandedSubs.contains(subID)
                    )

                    if expandedSubs.contains(subID) {
                        ForEach(itens) { lancamento in
                            lancamentoRow(lancamento)
                                .padding(.leading, 24)
                        }
                    }
                }
            }
        }
        .navigationTitle(categoriaNome)
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.2), value: expandedCategorias)
        .animation(.easeInOut(duration: 0.2), value: expandedSubs)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Histórico") {
                    LancamentosPorCategoriaHistoricoView(
                        vm: vm,
                        categoriaID: categoriaID
                    )
                }
            }
        }
    }
}

// MARK: - ROWS

private extension LancamentosPorCategoriaView {

    func categoriaRow(
        id: Int64,
        nome: String,
        total: Decimal,
        expanded: Bool
    ) -> some View {

        Button {
            toggle(&expandedCategorias, id)
        } label: {

            HStack(spacing: 12) {

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .foregroundStyle(Color.accentColor)
                   
                
                Text(nome)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(total.currency())
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.plain)
    }

    func subcategoriaRow(
        id: Int64,
        nome: String,
        total: Decimal,
        expanded: Bool
    ) -> some View {

        Button {
            toggle(&expandedSubs, id)
        } label: {

            HStack(spacing: 12) {

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .foregroundStyle(Color.accentColor)

                Text(nome)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(total.currency())
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    func lancamentoRow(_ lancamento: LancamentoModel) -> some View {

        NavigationLink {
            LancamentoDetalheView(
                lancamento: lancamento,
                vmLancamentos: vm
            )
        } label: {
            LancamentoRowConsumo(lancamento: lancamento)
        }
        .listRowInsets(
            EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        )
    }

    func toggle(_ set: inout Set<Int64>, _ id: Int64) {
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
    }
}

struct LancamentoRowConsumo: View {
    let lancamento: LancamentoModel
    
    init(
        lancamento: LancamentoModel
    ) {
        self.lancamento = lancamento
    }
    
    var body: some View {
        HStack(spacing: 12) {
            
            Circle()
                .fill(lancamento.categoria?.getCor().cor ?? .gray)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                
                    Text(lancamento.descricao)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(lancamento.dataVencimentoFormatada)
                        .font(.footnote)
                        .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(
                lancamento.valorComSinal,
                format: .currency(
                    code: lancamento.currencyCode
                )
            )
            .foregroundColor(.secondary)
        }
    }
}


// MARK: - Helper moeda

private extension Decimal {

    func currency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: self as NSDecimalNumber) ?? ""
    }
}

struct DonutChartView: View {

    let items: [CategoriaResumo]
    var lineWidth: CGFloat
    var size: CGFloat
    let detalhar: Bool
    let currencyCode: String

    init(items: [CategoriaResumo], lineWidth: CGFloat, size: CGFloat, detalhar: Bool = false, currencyCode: String) {
        self.items = items
        self.lineWidth = lineWidth
        self.size = size
        self.detalhar = detalhar
        self.currencyCode = currencyCode
    }

    private var total: Double {
        items.map(\.valor).reduce(0, +)
    }

    var body: some View {
        ZStack {
            if total > 0 {
                ForEach(items.indices, id: \.self) { index in
                    let start = startAngle(for: index)
                    let end = endAngle(for: index)
                    if end - start > 0.0001 { // desenha apenas se visível
                        Circle()
                            .trim(from: start, to: end)
                            .stroke(
                                items[index].cor,
                                style: StrokeStyle(
                                    lineWidth: lineWidth,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
            
            if detalhar && total > 0 {
                VStack(spacing: -2) {
                    Text(total, format: .currency(code: currencyCode))
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .frame(width: max(size, 10), height: max(size, 10))        
    }

    private func startAngle(for index: Int) -> CGFloat {
        let sum = items.prefix(index).map(\.percentual).reduce(0, +)
        return CGFloat(sum / 100)
    }

    private func endAngle(for index: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let sum = items.prefix(index + 1).map(\.valor).reduce(0, +)
        return CGFloat(sum / total)
    }
}


struct ConsumoListView: View {

    let items: [CategoriaResumo]
    let mostrarValores: Bool

    private var total: Double {
        items.reduce(0) { $0 + $1.valor }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                HStack {
                    Circle()
                        .fill(item.cor)
                        .frame(width: 10, height: 10)

                    Text(item.nome)

                    Spacer()
                    if(mostrarValores) {
                        
                        Text(percentualTexto(item))
                            .font(.body)
                            .foregroundStyle(.gray)
                    } else{
                        Text("•••")
                            .font(.body)
                            .foregroundStyle(.gray)
                        
                    }
                }
            }
        }
    }

    private func percentualTexto(_ item: CategoriaResumo) -> String {
        guard total > 0 else { return "0%" }

        let percentual = (item.valor / total) * 100
        return "\(Int(percentual.rounded()))%"
    }
}
