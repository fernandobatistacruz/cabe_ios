//
//  LancamentosPorCategoriaHistoricoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 08/02/26.
//

import SwiftUI

struct LancamentosPorCategoriaHistoricoView: View {
    
    @ObservedObject var vm: LancamentoListViewModel
    let categoriaID: Int64
    
    @State private var historico: [LancamentoModel] = []
    
    // MARK: - BODY
    
    
    var body: some View {
        
        List {
            
            ForEach(Array(agrupadoPorAno.enumerated()), id: \.element.ano) { index, grupo in
                Section {
                    
                    ForEach(grupo.itens) { item in
                        linhaResumo(item)
                    }
                    
                } header: {

                    VStack(alignment: .leading, spacing: 18) {

                        if index == 0 {
                            headerTotalGeral
                        }

                        HStack {

                            Text(String(grupo.ano))

                            Spacer()

                            Text(totalAnoFormatado(grupo))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Histórico")
        .task {
            await carregar()
        }
    }
}



private extension LancamentosPorCategoriaHistoricoView {

    var headerTotalGeral: some View {

        HStack {

            Text("Total")
                .font(.title3.weight(.heavy))
            
            Spacer()

            Text(totalGeralFormatado)
                .font(.title2.weight(.heavy))
        }
        .listRowBackground(Color.clear)
        .listRowInsets(
            EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0)
        )
    }
}

private extension LancamentosPorCategoriaHistoricoView {

    func linhaResumo(_ item: ResumoCategoriaAno) -> some View {

        HStack {

            Circle()
                .fill(item.cor)
                .frame(width: 12, height: 12)

            Text(item.nome)
                .lineLimit(1)

            Spacer()

            Text(item.valorFormatado)
                .foregroundColor(.secondary)
        }
        .listRowInsets(
            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
    }
    
    func totalAnoFormatado(_ grupo: GrupoAno) -> String {
        let total = grupo.itens.reduce(0) { $0 + $1.valor }

        return total.formatted(
            .currency(code: historico.first?.currencyCode ?? Locale.systemCurrencyCode)
        )
    }
}

private extension LancamentosPorCategoriaHistoricoView {
    
    struct GrupoAno {
        let ano: Int
        let itens: [ResumoCategoriaAno]
    }
    
    struct ResumoCategoriaAno: Identifiable {
        let id = UUID()
        let nome: String
        let valor: Double
        let cor: Color
        let currencyCode: String
        
        var valorFormatado: String {
            valor.formatted(.currency(code: currencyCode))
        }
    }
    
    var totalGeral: Double {
        historico.reduce(0) {
            $0 + NSDecimalNumber(decimal: $1.valorDividido).doubleValue
        }
    }
    
    var totalGeralFormatado: String {
        totalGeral.formatted(
            .currency(code: historico.first?.currencyCode ?? Locale.systemCurrencyCode)
        )
    }
    
    var agrupadoPorAno: [GrupoAno] {
        
        let despesas = historico.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            !$0.transferencia
        }
        
        let porAno = Dictionary(grouping: despesas, by: \.ano)
        
        return porAno.map { ano, lancs in
            
            let agrupadoCategoria = Dictionary(grouping: lancs) {
                $0.categoria?.id ?? 0
            }
            
            let itens = agrupadoCategoria.map { _, itens -> ResumoCategoriaAno in
                
                let categoria = itens.first?.categoria
                
                let total = itens.reduce(0) {
                    soma,
                    l in
                    soma + NSDecimalNumber(
                        decimal: l.valorDividido
                    ).doubleValue
                }
                
                return ResumoCategoriaAno(
                    nome: categoria?.isSub ?? false ? categoria?.nomeSubcategoria ?? "" : categoria?.nome ?? "",
                    valor: total,
                    cor: categoria?.getCor().cor ?? .gray,
                    currencyCode: itens.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            }
            .sorted {
                $0.nome.localizedCaseInsensitiveCompare($1.nome) == .orderedAscending
            }
            
            return GrupoAno(
                ano: ano,
                itens: itens
            )
        }
        .sorted { $0.ano > $1.ano }
    }
}

private extension LancamentosPorCategoriaHistoricoView {

    func carregar() async {
        do {
            historico = try await vm.repository
                .listarLancamentosAteAno(
                    vm.anoAtual,
                    categoriaID: categoriaID
                )
        }
        catch {
            print(error)
        }
    }
}
