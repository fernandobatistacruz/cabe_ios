//
//  ResumoAnualViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 04/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ResumoAnualViewModel: ObservableObject {

    let repository: LancamentoRepository

    @Published var anoSelecionado: Int
    @Published var resumoAnual: ResumoAnualModel?
    @Published var resumoMensal: [ResumoMensalModel] = []
    @Published var lancamentos: [LancamentoModel] = []
    @Published var despesasPorCategoria: [DespesaPorCategoriaModel] = []
    @Published var insights: [LocalizedStringKey] = []

    init(
        ano: Int,
        repository: LancamentoRepository
    ) {
        self.anoSelecionado = ano
        self.repository = repository
    }

    // MARK: - Carregar dados
    func carregarDados() async {
        do {
            lancamentos =  try await repository.listarLancamentosDoAno(ano: anoSelecionado)
            
            let lancamentosSemTransferencia = lancamentos.filter {
                !$0.transferencia
            }
            
            processar(lancamentosSemTransferencia)
        } catch {
            print("Erro ao carregar lançamentos do ano:", error)
        }
    }

    private func processar(_ lancamentos: [LancamentoModel]) {
        calcularResumoAnual(lancamentos)
        calcularResumoMensal(lancamentos)
        calcularDespesasPorCategoria(lancamentos)
        gerarInsights(lancamentos)
    }
}

// MARK: - Funções auxiliares
private extension ResumoAnualViewModel {

    func calcularResumoAnual(_ lancamentos: [LancamentoModel]) {
        let receita = lancamentos
            .filter { $0.tipo == Tipo.receita.rawValue }
            .map(\.valor)
            .reduce(0, +)

        let despesa = lancamentos
            .filter { $0.tipo == Tipo.despesa.rawValue }
            .map(\.valor)
            .reduce(0, +)

        let saldo = receita - despesa
        let taxa = receita > 0 ? saldo / receita : 0

        resumoAnual = ResumoAnualModel(
            ano: anoSelecionado,
            receitaTotal: receita,
            despesaTotal: despesa,
            saldo: saldo,
            taxaEconomia: taxa
        )
    }

    func calcularResumoMensal(_ lancamentos: [LancamentoModel]) {
        let agrupado = Dictionary(grouping: lancamentos, by: { $0.mes })

        resumoMensal = (1...12).map { mes in
            let itens = agrupado[mes] ?? []

            let receita = itens
                .filter { $0.tipo == Tipo.receita.rawValue }
                .map(\.valor)
                .reduce(0, +)

            let despesa = itens
                .filter { $0.tipo == Tipo.despesa.rawValue }
                .map(\.valor)
                .reduce(0, +)

            return ResumoMensalModel(
                mes: mes,
                receita: receita,
                despesa: despesa
            )
        }
    }

    func calcularDespesasPorCategoria(_ lancamentos: [LancamentoModel]) {
        let despesas = lancamentos.filter { $0.tipo == Tipo.despesa.rawValue }

        let agrupado = Dictionary(grouping: despesas, by: { $0.categoriaID })

        despesasPorCategoria = agrupado.compactMap { _, itens in
            guard let categoria = itens.first?.categoria else { return nil }
            let total = itens.map(\.valor).reduce(0, +)
            return DespesaPorCategoriaModel(categoria: categoria, total: total)
        }
        .sorted { $0.total > $1.total }
    }

    func gerarInsights(_ lancamentos: [LancamentoModel]) {
        var frases: [LocalizedStringKey] = []

        // Meses negativos
        let mesesNegativos = resumoMensal.filter { $0.saldo < 0 }.count
        if mesesNegativos > 0 {
            frases.append("⚠️ Em \(mesesNegativos) meses suas despesas superaram a receita.")
        }

        // Maior despesa por categoria
        if let maior = despesasPorCategoria.first {
            frases
                .append(
                    "🏷️ \(maior.categoria.nome) foi sua maior despesa do ano."
                )
        }

        // Despesas recorrentes
        let despesas = lancamentos.filter { $0.tipo == Tipo.despesa.rawValue }
        let recorrentes = despesas.filter { $0.tipoRecorrente != .nunca }

        if !despesas.isEmpty {
            let totalDespesas = despesas.map(\.valor).reduce(0, +)
            let totalRecorrentes = recorrentes.map(\.valor).reduce(0, +)
            let percentual = totalDespesas > 0 ? (totalRecorrentes / totalDespesas) * 100 : 0
            frases.append("🔁 \(String(format: "%.0f", NSDecimalNumber(decimal: percentual).doubleValue))% das despesas foram recorrentes.")
        }
        
        insights = frases
    }

}

// MARK: - Models
struct ResumoAnualModel {
    let ano: Int
    let receitaTotal: Decimal
    let despesaTotal: Decimal
    let saldo: Decimal
    let taxaEconomia: Decimal
}

struct ResumoMensalModel: Identifiable {
    let id = UUID()
    let mes: Int
    let receita: Decimal
    let despesa: Decimal

    var saldo: Decimal { receita - despesa }

    var mesNome: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.monthSymbols[mes - 1]
    }
}

struct DespesaPorCategoriaModel: Identifiable {
    let id = UUID()
    let categoria: CategoriaModel
    let total: Decimal
}

