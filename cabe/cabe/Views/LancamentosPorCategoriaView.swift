//
//  LancamentosPorCategoriaView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/02/26.
//

import SwiftUI
import Charts

struct LancamentosPorCategoriaView: View {
    
    @ObservedObject var vm: LancamentoListViewModel
    let lancamentos: [LancamentoModel]
    let categoria: CategoriaResumo
       
    @State private var expandedCategorias: Set<Int64>
    @State private var expandedSubs: Set<Int64> = []
 
    init(
        vm: LancamentoListViewModel,
        lancamentos: [LancamentoModel],
        categoria: CategoriaResumo,
       
    ) {
        self.vm = vm
        self.lancamentos = lancamentos
        self.categoria = categoria
        _expandedCategorias = State(initialValue: [])
    }

    private var lancamentosCategoriaPrincipal: [LancamentoModel] {
        lancamentos.filter {
            $0.categoriaID == categoria.categoriaID &&
            $0.tipo == Tipo.despesa.rawValue
        }
    }

    private var lancamentosPorSub: [Int64: [LancamentoModel]] {
        Dictionary(
            grouping: lancamentos.filter {
                $0.categoria?.pai == categoria.categoriaID &&
                $0.tipo == Tipo.despesa.rawValue
            },
            by: { $0.categoriaID }
        )
    }

    private var corCategoriaPrincipalOriginal: Color {
        lancamentosCategoriaPrincipal.first?.categoria?.cor ?? categoria.cor
    }

    private func total(_ itens: [LancamentoModel]) -> Decimal {
        itens.reduce(0) { $0 + $1.valorDividido }
    }
  
    private var totalCategoriaCompleta: Decimal {
        total(lancamentosCategoriaPrincipal) +
        total(lancamentosPorSub.values.flatMap { $0 })
    }

    private var subcategoriasNaOrdemDaLista: [Int64] {
        lancamentosPorSub.keys.sorted()
    }

    var body: some View {

        List {
            
            Section {
                VStack (alignment: .leading) {
                    Text("Categoria e Subcategoria")
                        .font(.headline)
                    graficoBarrasCategorias
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
                       
            Section {
                
                categoriaRow(
                    id: categoria.categoriaID,
                    nome: categoria.nome,
                    total: total(lancamentosCategoriaPrincipal),
                    cor: corCategoriaPrincipalOriginal,
                    expanded: expandedCategorias.contains(categoria.categoriaID)
                )
                
                if expandedCategorias.contains(categoria.categoriaID) {
                    
                    ForEach(lancamentosCategoriaPrincipal) { lancamento in
                        lancamentoRow(lancamento)
                    }
                }
                
                ForEach(subcategoriasNaOrdemDaLista, id: \.self) { subID in
                    
                    let itens = lancamentosPorSub[subID] ?? []
                    
                    let nomeSub =
                    itens.first?.categoria?.nomeSubcategoria
                    ?? "Subcategoria"
                    
                    subcategoriaRow(
                        id: subID,
                        nome: nomeSub,
                        total: total(itens),
                        cor: itens.first?.categoria?.cor ?? .gray,
                        expanded: expandedSubs.contains(subID)
                    )
                    
                    if expandedSubs.contains(subID) {
                        ForEach(itens) { lancamento in
                            lancamentoRow(lancamento)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Lançamentos")
                    Spacer()
                    Text(totalCategoriaCompleta.currency())
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .navigationTitle(categoria.nome)
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.2), value: expandedCategorias)
        .animation(.easeInOut(duration: 0.2), value: expandedSubs)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Histórico") {
                    LancamentosPorCategoriaHistoricoView(
                        vm: vm,
                        categoria: categoria
                    )
                }
            }
        }
    }
    
    private var dadosGraficoBarras: [CategoriaBarItem] {
        var itens: [CategoriaBarItem] = []

        let totalPrincipal = total(lancamentosCategoriaPrincipal)
        if !totalPrincipal.isZero {
            itens.append(
                CategoriaBarItem(
                    id: categoria.categoriaID,
                    nome: categoria.nome,
                    valor: totalPrincipal,
                    cor: corCategoriaPrincipalOriginal
                )
            )
        }

        for subID in subcategoriasNaOrdemDaLista {
            let itensSub = lancamentosPorSub[subID] ?? []
            let nomeSub = itensSub.first?.categoria?.nomeSubcategoria ?? "Subcategoria"
            let totalSub = total(itensSub)

            itens.append(
                CategoriaBarItem(
                    id: subID,
                    nome: nomeSub,
                    valor: totalSub,
                    cor: itensSub.first?.categoria?.cor ?? .gray
                )
            )
        }

        return itens.sorted { $0.valor > $1.valor }
    }

    @ViewBuilder
    private var graficoBarrasCategorias: some View {
        if dadosGraficoBarras.allSatisfy({ $0.valor == 0 }) {
            EmptyView()
        } else {
            let temApenasUmaLinha = dadosGraficoBarras.count == 1
            
            if temApenasUmaLinha, let itemUnico = dadosGraficoBarras.first {
                Chart(dadosGraficoBarras) { item in
                    BarMark(
                        x: .value("Valor", item.valor),
                        y: .value("Categoria", item.nome),
                        height: .fixed(12)
                    )
                    .foregroundStyle(item.cor.gradient)
                    .cornerRadius(5)
                }
                .frame(height: min(CGFloat(dadosGraficoBarras.count * 40), 320))
                .chartXScale(domain: 0...itemUnico.valor)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel {}
                    }
                }
            } else {
                Chart(dadosGraficoBarras) { item in
                    BarMark(
                        x: .value("Valor", item.valor),
                        y: .value("Categoria", item.nome),
                        height: .fixed(12)
                    )
                    .foregroundStyle(item.cor.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text(
                            item.valor
                                .abreviado(currencyCode: categoria.currencyCode)
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .frame(height: min(CGFloat(dadosGraficoBarras.count * 40), 320))
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel {}
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
            }
        }
    }
}

private struct CategoriaBarItem: Identifiable {
    let id: Int64
    let nome: String
    let valor: Decimal
    let cor: Color
}

private extension LancamentosPorCategoriaView {

    func categoriaRow(
        id: Int64,
        nome: String,
        total: Decimal,
        cor: Color,
        expanded: Bool
    ) -> some View {

        Button {
            toggle(&expandedCategorias, id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: categoria.icone)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(categoria.cor)
                
                Text(nome)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                Spacer()

                Text(total.currency())
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    func subcategoriaRow(
        id: Int64,
        nome: String,
        total: Decimal,
        cor: Color,
        expanded: Bool
    ) -> some View {

        Button {
            toggle(&expandedSubs, id)
        } label: {

            HStack(spacing: 12) {
                Image(systemName: categoria.icone)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(categoria.cor)
                

                Text(nome)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                Spacer()

                Text(total.currency())
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 2)
        }
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
            EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 16)
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
    
    init(lancamento: LancamentoModel) {
        self.lancamento = lancamento
    }
    
    var body: some View {
        let cor = lancamento.categoria?.cor ?? .gray
        HStack(spacing: 12) {
            Circle()
                .fill(cor.gradient)
                .frame(width: 10, height: 10)
                        
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
                lancamento.valorDividido,
                format: .currency(
                    code: lancamento.currencyCode
                )
            )
            .foregroundColor(.secondary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.leading, 24)
    }
}

private extension Decimal {
    func currency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: self as NSDecimalNumber) ?? ""
    }
}
