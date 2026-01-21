import SwiftUI
import Charts

// MARK: - View
struct ResumoAnualView: View {

    @StateObject private var vm: ResumoAnualViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @State private var showingPaywall = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    
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
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
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
        .navigationTitle("Resumo")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    ForEach((2020...Calendar.current.component(.year, from: .now)).reversed(), id: \.self) { ano in
                        Button(String(ano)) {
                            vm.anoSelecionado = ano
                        }
                    }
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
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isExporting)
            }
        }
        .task {
            await vm.carregarDados()
        }
        .onChange(of: vm.anoSelecionado) { _ in
            Task {
                await vm.carregarDados()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
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
        }
    }
    
    private func exportarCSV() async {
        guard !isExporting else { return }

        isExporting = true

        defer { isExporting = false }

        do {
            let url = try await ExportarLancamentos.export(
                lancamentos: vm.lancamentos,
                fileName: "lancamentos_anuais.csv"
            )

            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }

    // MARK: - Cards
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

    // MARK: - Evolução Mensal
    var graficoReceitaDespesa: some View {
        ChartCard(titulo: "Evolução Mensal") {
            Chart(vm.resumoMensal) { item in
                BarMark(
                    x: .value("Mês", item.mes),
                    y: .value("Receita", item.receita.doubleValue)
                )
                .foregroundStyle(.green)

                BarMark(
                    x: .value("Mês", item.mes),
                    y: .value("Despesa", item.despesa.doubleValue)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 220)
        }
    }


    // MARK: - Insights
    var insightsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Análises")
                .font(.headline)

            ForEach(vm.insights.indices, id: \.self) { index in
                let texto = vm.insights[index]
                InsightRowView(texto: texto)
            }
        }
    }
    
    func graficoCategoriasHorizontal(_ categorias: [DespesaPorCategoriaModel],_ currencyCode: String) -> some View {
        Chart(categorias) { item in
            BarMark(
                x: .value("Total", item.total.doubleValue),
                y: .value("Categoria", item.categoria.nome)
            )
            .foregroundStyle(.blue)
            .annotation(position: .trailing) {
                Text(item.total.abreviado(currencyCode: currencyCode))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                                .first?.currencyCode ?? "USD")
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


// MARK: - Card Resumo
struct CardResumoView: View {
    let titulo: LocalizedStringKey
    let valor: Decimal
    let cor: Color
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(valor.abreviado(currencyCode: currencyCode))
                .font(.headline)
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



// MARK: - Insight Row
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
