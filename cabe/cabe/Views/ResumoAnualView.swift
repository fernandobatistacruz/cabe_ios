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
        .refreshable {
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
        HStack(spacing: 12) {
            CardResumoView(titulo: "Receita", valor: resumo.receitaTotal, cor: .green)
            CardResumoView(titulo: "Despesa", valor: resumo.despesaTotal, cor: .red)
            CardResumoView(titulo: "Saldo", valor: resumo.saldo, cor: resumo.saldo >= 0 ? .green : .red)
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
    
    func graficoCategoriasHorizontal(_ categorias: [DespesaPorCategoriaModel]) -> some View {
        Chart(categorias) { item in
            BarMark(
                x: .value("Total", item.total.doubleValue),
                y: .value("Categoria", item.categoria.nome)
            )
            .foregroundStyle(.blue)
            .annotation(position: .trailing) {
                Text(item.total.abreviado())
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
        let categoriasValidas = vm.despesasPorCategoria
            .filter { $0.total > 0 && !$0.categoria.nome.isEmpty }

        return VStack(spacing: 16) {

            if categoriasValidas.isEmpty {
                CardContainer {
                    Text("Nenhuma despesa registrada")
                        .foregroundColor(.secondary)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                }
            } else {
                CardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Despesas por Categoria")
                            .font(.headline)

                        graficoCategoriasHorizontal(categoriasValidas)
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
    func abreviado() -> String {
        let value = NSDecimalNumber(decimal: self).doubleValue

        switch abs(value) {
        case 1_000_000...:
            return String(format: "R$ %.1f mi", value / 1_000_000)
        case 1_000...:
            return String(format: "R$ %.1f mil", value / 1_000)
        default:
            return String(format: "R$ %.0f", value)
        }
    }
}


// MARK: - Card Resumo
struct CardResumoView: View {
    let titulo: LocalizedStringKey
    let valor: Decimal
    let cor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(valor.abreviado())
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
