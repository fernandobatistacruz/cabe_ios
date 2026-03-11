//
//  LancamentosPorCategoriaHistoricoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 08/02/26.
//

import SwiftUI

struct LancamentosPorCategoriaHistoricoView: View {
    
    @ObservedObject var vm: LancamentoListViewModel
    let categoria: CategoriaResumo
    @State private var historico: [LancamentoModel] = []
    @EnvironmentObject var sub: SubscriptionManager
    @State private var showingPaywall = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    
    var body: some View {
        
        List {
            Section {
                headerTotalGeral
                    .padding(.vertical, 8)
            }
            
            ForEach(Array(agrupadoPorAno.enumerated()), id: \.element.ano) { index, grupo in
                
                Section{
                    ForEach(grupo.itens) { item in
                        linhaResumo(item)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        HStack {
                            
                            Text(String(grupo.ano))
                            
                            Spacer()
                            
                            Text(totalAnoFormatado(grupo))
                                .font(.subheadline)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }
        }
        .navigationTitle("Histórico")
        .toolbar {           
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
        .task {
            await carregar()
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheetView(
                message: String(localized: "Relatório da categoria \(String(categoria.nome)) extraído do Cabe"),
                subject: String(localized: "Relatório da categoria \(String(categoria.nome)) extraído do Cabe"),
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
}

private extension LancamentosPorCategoriaHistoricoView {

    var headerTotalGeral: some View {
        
        HStack(spacing: 10) {
            Image(
                systemName: categoria.icone
            )
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(categoria.cor)
            
            VStack(alignment: .leading) {
                Text(categoria.nome)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .font(.title2.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(totalGeralFormatado)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private extension LancamentosPorCategoriaHistoricoView {

    func linhaResumo(_ item: ResumoCategoriaAno) -> some View {

        HStack {

            Text(item.nome)
                .lineLimit(1)

            Spacer()

            Text(item.valorFormatado)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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
    
    var totalGeral: Decimal {
        historico.reduce(0) { $0 + $1.valorDividido }
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
                    cor: categoria?.cor ?? .gray,
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

    private func carregar() async {
        do {
            historico = try await vm.repository
                .listarLancamentosAteAno(
                    Calendar.current.component(.year, from: Date()),
                    categoriaID: categoria.categoriaID
                )
        }
        catch {
            print(error)
        }
    }
    
    private func exportarCSV() async {
        guard !isExporting else { return }

        isExporting = true

        defer { isExporting = false }

        do {
            let url = try await ExportarLancamentos.export(
                lancamentos: historico,
                fileName: "\(String(localized: "lancamentos"))_\(String(categoria.nome.lowercased())).csv"
            )

            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }
}
