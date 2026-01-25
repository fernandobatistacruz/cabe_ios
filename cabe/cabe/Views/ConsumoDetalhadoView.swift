//
//  ConsumoDetalhadoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/01/26.
//

import SwiftUI

struct ConsumoDetalhadoView: View {

    @ObservedObject var vm: LancamentoListViewModel
    let items: [CategoriaResumo]
    
    private var isEmpty: Bool {
        items.isEmpty
    }

    var body: some View {
        Group {
            if isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Consumo")
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: - Card do Gráfico
                VStack {
                    DonutChartView(
                        items: items,
                        lineWidth: 22,
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

                // MARK: - Legenda / Detalhamento
                VStack(alignment: .leading, spacing: 12) {

                    Text("Detalhamento")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        ForEach(items.indices, id: \.self) { index in
                            let item = items[index]

                            if item.categoriaID >= 0 {
                                NavigationLink {
                                    LancamentosPorCategoriaView(
                                        vm: vm,
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

                            if index < items.count - 1 {
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
        .contentShape(Rectangle()) // melhora o toque
    }
}


struct LancamentosPorCategoriaView: View {

    @ObservedObject var vm: LancamentoListViewModel
    let categoriaID: Int64
    let categoriaNome: String

    private var lancamentosFiltrados: [LancamentoModel] {
        vm.lancamentos.filter {
            ($0.categoriaID == categoriaID || $0.categoria?.pai == categoriaID)
            && $0.tipo == Tipo.despesa.rawValue
        }
    }

    var body: some View {
        List {
            ForEach(lancamentosFiltrados) { lancamento in
                HStack(spacing: 4) {
                    Text(lancamento.descricao)
                    
                    Spacer()

                    Text(
                        lancamento.valor,
                        format: .currency(
                            code: lancamento.conta?.currencyCode ?? Locale.current.currency?.identifier ?? Locale.systemCurrencyCode
                        )
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(categoriaNome)
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
