import SwiftUI
import Charts

struct ResumoAnualView: View {

    @StateObject private var vm: ResumoAnualViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @State private var showingPaywall = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    @State private var showingYearPicker = false
    @State private var tempDate = Date()
    @State private var anoDraft: Int = 0
    @State private var isLoadingData = false
    
    init(
        ano: Int = Calendar.current.component(.year, from: .now),
        repository: LancamentoRepository = LancamentoRepository()
    ) {
        _vm = StateObject(
            wrappedValue: ResumoAnualViewModel(
                ano: ano,
                repository: repository
            )
        )        
        anoDraft = ano
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if isLoadingData {
                loadingState
            } else {
                if vm.lancamentos.isEmpty {
                    emptyState
                }
                else {
                    contentState
                }
            }
        }
        .navigationTitle("Resumo")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    let comps = DateComponents(year: vm.anoSelecionado)
                    tempDate = Calendar.current.date(from: comps) ?? .now
                    showingYearPicker = true
                } label: {
                    Text("\(String(vm.anoSelecionado))")
                        .font(.subheadline)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if sub.isSubscribed {
                        Task {
                            await exportarCSV()
                        }
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isExporting)
            }
        }
        .sheet(isPresented: $showingYearPicker) {
            NavigationStack {

                let years = Array(2020...(anoAtual + 10)).reversed()

                VStack {
                    Picker("Ano", selection: $anoDraft) {
                        ForEach(years, id: \.self) { ano in
                            Text(String(ano)).tag(ano)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                }
                .navigationTitle("Ano")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    anoDraft = vm.anoSelecionado
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Hoje") {
                            anoDraft = anoAtual
                            vm.anoSelecionado = anoAtual
                            showingYearPicker = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("OK") {
                            vm.anoSelecionado = anoDraft
                            showingYearPicker = false
                        }
                    }
                }
            } .presentationDetents([.fraction(0.35)])
        }
        .task {
            isLoadingData = true
            await vm.carregarDados()
            isLoadingData = false
        }
        .onChange(of: vm.anoSelecionado) { _ in
            Task {
                isLoadingData = true
                await vm.carregarDados()
                isLoadingData = false
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheetView(
                message: String(localized: "Relatório anual de \(String(vm.anoSelecionado)) extraído do Cabe"),
                subject: String(localized: "Relatório anual de \(String(vm.anoSelecionado)) extraído do Cabe"),
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
        }
    }
    
    private var contentState: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let resumo = vm.resumoAnual {
                    cardsResumo(resumo)
                }
                
                graficoReceitaDespesa
                graficoCategorias
                
                if !vm.insights.isEmpty {
                    insightsView
                }
            }
            .padding()
        }
    }
    
    private var loadingState: some View {
        VStack {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("Nenhum Registro")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var anoAtual: Int {
        Calendar.current.component(.year, from: .now)
    }
    
    private func exportarCSV() async {
        guard !isExporting else { return }

        isExporting = true

        defer { isExporting = false }

        do {
            let url = try await ExportarLancamentos.export(
                lancamentos: vm.lancamentos,
                fileName: "\(String(localized: "lancamentos_anuais")).csv"                
            )

            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }
   
    func cardsResumo(_ resumo: ResumoAnualModel) -> some View {
        let currentCode = vm.lancamentos.first?.currencyCode ?? ""
        
        return HStack(spacing: 12) {
            CardResumoView(
                titulo: "Receita",
                valor: resumo.receitaTotal,
                cor: .green,
                currencyCode: currentCode
            )
            CardResumoView(
                titulo: "Despesa",
                valor: resumo.despesaTotal,
                cor: .red,
                currencyCode: currentCode
            )
            CardResumoView(
                titulo: "Saldo",
                valor: resumo.saldo,
                cor: resumo.saldo >= 0 ? .green : .red,
                currencyCode: currentCode
            )
        }
    }
  
    var graficoReceitaDespesa: some View {
        ChartCard(titulo: "Evolução Mensal") {
            Chart(vm.resumoMensal, id: \.mes) { item in
                BarMark(
                    x: .value("Mês", "\(item.mes)"),
                    y: .value("Valor", item.receita.doubleValue),
                    width: .fixed(10)
                )
                .cornerRadius(3)
                .position(by: .value("Tipo", "Receita"))
                .foregroundStyle(.green.gradient)
               
                BarMark(
                    x: .value("Mês", "\(item.mes)"),
                    y: .value("Valor", item.despesa.doubleValue),
                    width: .fixed(10)
                )
                .cornerRadius(3)
                .position(by: .value("Tipo", "Despesa"))
                .foregroundStyle(.red.gradient)
            }
            .chartForegroundStyleScale([
                String(localized: "Receita"): .green,
                String(localized: "Despesa"): .red
            ])
            .chartLegend(position: .bottom, spacing: 16)
            .chartXAxis {
                AxisMarks(values: vm.resumoMensal.map { "\($0.mes)" }) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let mesString = value.as(String.self),
                           let mesInt = Int(mesString) {
                            Text(primeiraLetraDoMes(mesInt))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self),
                           doubleValue != 0 {
                            Text(
                                Decimal(doubleValue)
                                    .abreviado(currencyCode: vm.lancamentos.first?.currencyCode ?? "")
                            )
                        }
                    }
                }
            }
            .frame(height: 240)
            .padding(.vertical, 5)
        }
    }
    
    private static let monthSymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.monthSymbols
    }()

    private func primeiraLetraDoMes(_ mes: Int) -> String {
        guard mes >= 1 && mes <= Self.monthSymbols.count else { return "" }
        return String(Self.monthSymbols[mes - 1].prefix(1)).capitalized
    }
    
    var insightsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Análises")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ForEach(vm.insights.indices, id: \.self) { index in
                let texto = vm.insights[index]
                InsightRowView(texto: texto)
            }
        }
    }
    
    func graficoCategoriasHorizontal(_ categorias: [DespesaPorCategoriaModel],_ currencyCode: String) -> some View {
        Chart(categorias) { item in
            BarMark(
                x: .value("Total", item.total),
                y: .value("Categoria", item.categoria.nome),
                width: .fixed(10)
            )
            .cornerRadius(3)
            .foregroundStyle(.blue.gradient)
            .annotation(position: .trailing) {
                Text(item.total.abreviado(currencyCode: currencyCode))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {}
            }
        }
        .frame(
            height: min(CGFloat(categorias.count * 36), 320)
        )
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption)
            }
        }
    }
    
    var graficoCategorias: some View {
        let categoriasValidas = Array(
            vm.despesasPorCategoria
                .filter { $0.total > 0 && !$0.categoria.nome.isEmpty }
                .prefix(9)
        )

        return VStack(spacing: 16) {

            if categoriasValidas.isEmpty {
                CardContainer {
                    Text("Nenhuma Despesa")
                        .foregroundColor(.secondary)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                }
            } else {
                CardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Despesas por Categoria")
                            .font(.headline)

                        graficoCategoriasHorizontal(
                            categoriasValidas,
                            vm.lancamentos
                                .first?.currencyCode ?? Locale.systemCurrencyCode)
                    }
                }
            }
        }
    }
    
    struct CardContainer<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }
}

private extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}

extension Decimal {

    func abreviado(
        currencyCode: String,
        locale: Locale = .current
    ) -> String {

        let value = NSDecimalNumber(decimal: self).doubleValue
        let absValue = abs(value)

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = absValue >= 1_000 ? 1 : 0
        
        formatter.currencySymbol = ""
        formatter.internationalCurrencySymbol = ""
        formatter.positivePrefix = ""
        formatter.positiveSuffix = ""
        formatter.negativePrefix = "-"
        formatter.negativeSuffix = ""

        let thousandSuffix = String(
            localized: "suffix_thousand",
            bundle: .main
        )

        let millionSuffix = String(
            localized: "suffix_million",
            bundle: .main
        )

        switch absValue {
        case 1_000_000...:
            let number = value / 1_000_000
            let formatted = formatter.string(from: NSNumber(value: number)) ?? ""
            return "\(formatted) \(millionSuffix)"

        case 1_000...:
            let number = value / 1_000
            let formatted = formatter.string(from: NSNumber(value: number)) ?? ""
            return "\(formatted) \(thousandSuffix)"

        default:
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? ""
        }
    }
}

struct CardResumoView: View {
    let titulo: LocalizedStringKey
    let valor: Decimal
    let cor: Color
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Text(valor.abreviado(currencyCode: currencyCode))
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundColor(cor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct InsightRowView: View {
    let texto: LocalizedStringKey

    var body: some View {
        Text(texto)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

struct ChartCard<Content: View>: View {
    let titulo: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.headline)
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

