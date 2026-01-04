import SwiftUI
import Charts

// MARK: - View
struct ResumoAnualView: View {

    @StateObject private var vm: ResumoAnualViewModel

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
        ScrollView {
            VStack(spacing: 24) {
                if let resumo = vm.resumoAnual {
                    cardsResumo(resumo)
                }

                graficoReceitaDespesa
                graficoCategoria
                insightsView
            }
            .padding()
        }
        .navigationTitle("Resumo Anual")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
    }

    // MARK: - Cards
    func cardsResumo(_ resumo: ResumoAnualModel) -> some View {
        HStack(spacing: 12) {
            CardResumoView(titulo: "Receita", valor: resumo.receitaTotal, cor: .green)
            CardResumoView(titulo: "Despesa", valor: resumo.despesaTotal, cor: .red)
            CardResumoView(
                titulo: "Saldo",
                valor: resumo.saldo,
                cor: resumo.saldo >= 0 ? .green : .red
            )
        }
    }

    // MARK: - Evolução Mensal
    var graficoReceitaDespesa: some View {
        VStack(alignment: .leading) {
            Text("Evolução Mensal")
                .font(.headline)

            Chart(vm.resumoMensal) { item in
                BarMark(
                    x: .value("Mês", item.mes),
                    y: .value("Receita", NSDecimalNumber(decimal: item.receita).doubleValue)
                )
                .foregroundStyle(.green)

                BarMark(
                    x: .value("Mês", item.mes),
                    y: .value("Despesa", NSDecimalNumber(decimal: item.despesa).doubleValue)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 220)
        }
    }

    // MARK: - Insights
    var insightsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.headline)

            ForEach(vm.insights, id: \.self) { texto in
                InsightRowView(texto: texto)
            }
        }
    }
}

private extension ResumoAnualView {

    var graficoCategoria: some View {
        VStack(alignment: .leading) {
            Text("Despesas por Categoria")
                .font(.headline)

            if #available(iOS 17.0, *) {
                graficoPizzaCategoria
            } else {
                graficoBarrasCategoria
            }
        }
    }

    @available(iOS 17.0, *)
    var graficoPizzaCategoria: some View {
        let categoriasValidas = vm.despesasPorCategoria.prefix(6)
            .filter { $0.total > 0 && !$0.categoria.nome.isEmpty }

        if categoriasValidas.isEmpty {
            return AnyView(
                Text("Nenhuma despesa registrada")
                    .foregroundColor(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
            )
        }

        return AnyView(
            Chart(categoriasValidas) { item in
                SectorMark(
                    angle: .value("Total", NSDecimalNumber(decimal: item.total).doubleValue)
                )
                .foregroundStyle(by: .value("Categoria", item.categoria.nome))
                .annotation(position: .overlay) {
                    Text(item.categoria.nome)
                        .font(.caption2)
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
        )
    }

    var graficoBarrasCategoria: some View {
        let categoriasValidas = vm.despesasPorCategoria.prefix(6)
            .filter { $0.total > 0 && !$0.categoria.nome.isEmpty }

        if categoriasValidas.isEmpty {
            return AnyView(
                Text("Nenhuma despesa registrada")
                    .foregroundColor(.secondary)
                    .frame(height: 220)
            )
        }

        return AnyView(
            Chart(categoriasValidas) { item in
                BarMark(
                    x: .value("Categoria", item.categoria.nome),
                    y: .value("Total", NSDecimalNumber(decimal: item.total).doubleValue)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 220)
        )
    }

}


// MARK: - Card Resumo
struct CardResumoView: View {
    let titulo: String
    let valor: Decimal
    let cor: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(valor, format: .currency(code: "BRL").precision(.fractionLength(0)))
                .font(.headline)
                .foregroundColor(cor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Insight Row
struct InsightRowView: View {
    let texto: String

    var body: some View {
        Text(texto)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

