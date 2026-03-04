//
//  LancamentosPorCategoriaView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/02/26.
//

import SwiftUI

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

        _expandedCategorias = State(initialValue: [categoria.categoriaID])
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

    private func total(_ itens: [LancamentoModel]) -> Decimal {
        itens.reduce(0) { $0 + $1.valorDividido }
    }
  
    private var totalCategoriaCompleta: Decimal {
        total(lancamentosCategoriaPrincipal) +
        total(lancamentosPorSub.values.flatMap { $0 })
    }

    var body: some View {

        List {
            /*
            VStack {
                DonutChartView(
                    items: gastosPorCategoriaDetalhado,
                    lineWidth: 26,
                    size: 180,
                    detalhar: true,
                    currencyCode: vm.lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode,
                    round: false
                )
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            */
            
            Section {
                
                categoriaRow(
                    id: categoria.categoriaID,
                    nome: String(localized: "Principal"),
                    total: total(lancamentosCategoriaPrincipal),
                    cor: categoria.cor,
                    expanded: expandedCategorias.contains(categoria.categoriaID)
                )
                
                if expandedCategorias.contains(categoria.categoriaID) {
                    
                    ForEach(lancamentosCategoriaPrincipal) { lancamento in
                        lancamentoRow(lancamento)
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
                            cor: itens.first?.categoria?.cor ?? Color.gray,
                            expanded: expandedSubs.contains(subID)
                        )
                        
                        if expandedSubs.contains(subID) {
                            ForEach(itens) { lancamento in
                                lancamentoRow(lancamento)
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Total")
                    Spacer()
                    Text(totalCategoriaCompleta.currency())
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
                        categoriaID: categoria.categoriaID
                    )
                }
            }
        }
    }
    
    var gastosPorCategoriaDetalhado: [CategoriaResumo] {

        let despesas = vm.lancamentos.filter {
            ($0.categoriaID == categoria.categoriaID || $0.categoria?.pai == categoria.categoriaID) &&
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

        let totaisBase = agrupado.map { (id, itens) in
            let total = itens.reduce(0) { $0 + $1.valor }
            let item = itens[0]
            
            return (
                categoriaID: id,
                nome: item.nome,
                valor: total,
                cor: item.cor
            )
        }

        let totalGeral = totaisBase.reduce(0) { $0 + $1.valor }
        guard totalGeral > 0 else { return [] }

        return totaisBase
            .sorted { $0.valor > $1.valor }
            .enumerated()
            .map { index, item in
                CategoriaResumo(
                    categoriaID: item.categoriaID,
                    nome: item.nome,
                    valor: item.valor,
                    percentual: (item.valor / totalGeral) * 100,
                    cor: item.cor.variation(index: index),
                    currencyCode: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            }
    }
    
    private func categoriaPrincipalInfo(
        from categoria: CategoriaModel?
    ) -> (id: Int64, nome: String, cor: Color) {
        if let categoria, categoria.isSub {
            return (
                id: categoria.id ?? 0,
                nome: categoria.nomeSubcategoria ?? "",
                cor: categoria.cor
            )
        }

        return (
            id: categoria?.id ?? 0,
            nome: categoria?.nome ?? "",
            cor: categoria?.cor ?? .gray
        )
    }
}

extension Color {
    func variation(index: Int) -> Color {
        #if os(iOS)
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            
            let step = CGFloat(index) * 0.08
            let newBrightness = max(min(brightness - step, 1.0), 0.15)
            
            return Color(
                UIColor(
                    hue: hue,
                    saturation: saturation,
                    brightness: newBrightness,
                    alpha: alpha
                )
            )
        }
        
        return self
        #else
        return self
        #endif
    }
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
                Circle()
                    .fill(cor)
                    .frame(width: 10, height: 10)
                
                Text(nome)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                Spacer()

                Text(total.currency())
                    .foregroundColor(.secondary)
                
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
                Circle()
                    .fill(cor)
                    .frame(width: 10, height: 10)

                Text(nome)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                Spacer()

                Text(total.currency())
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 2)
            .padding(.leading, 10)
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
        HStack(spacing: 12) {
            Circle()
                .fill(lancamento.categoria?.cor ?? .gray)
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
        }
        .padding(.leading, 18)
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
