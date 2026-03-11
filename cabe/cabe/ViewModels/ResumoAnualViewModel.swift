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
   
    func carregarDados() async {
        do {
            lancamentos =  try await repository.listarLancamentosDoAno(ano: anoSelecionado)
            processar(lancamentos)
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

private extension ResumoAnualViewModel {

    func calcularResumoAnual(_ lancamentos: [LancamentoModel]) {
        let totalReceita = lancamentos
            .filter { $0.tipo == Tipo.receita.rawValue }
            .map(\.valor)
            .reduce(0, +)

        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            $0.transferencia == false
        }
        
        var totalDespesas: Decimal {
            despesas.reduce(0) { total, lancamento in
                let valorConsiderado = lancamento.valorDividido
                return (total + valorConsiderado)
            }
        }
        
        var saldo: Decimal {
            totalReceita - totalDespesas
        }
        
        let taxa = totalReceita > 0 ? saldo / totalReceita : 0

        resumoAnual = ResumoAnualModel(
            ano: anoSelecionado,
            receitaTotal: totalReceita,
            despesaTotal: totalDespesas,
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

            let despesas = itens.filter {
                $0.tipo == Tipo.despesa.rawValue &&
                $0.transferencia == false
            }
            
            var despesa: Decimal {
                despesas.reduce(0) { total, lancamento in
                    let valorConsiderado = lancamento.valorDividido
                    return (total + valorConsiderado)
                }
            }

            return ResumoMensalModel(
                mes: mes,
                receita: receita,
                despesa: despesa
            )
        }
    }

    func calcularDespesasPorCategoria(_ lancamentos: [LancamentoModel]) {

        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            $0.transferencia == false
        }

        let agrupado = Dictionary(grouping: despesas) { lancamento -> Int64 in
            guard let categoria = lancamento.categoria,
                  let id = categoria.id
            else { return -1 }

            return categoria.pai ?? id
        }

        despesasPorCategoria = agrupado.compactMap { (_, itens) -> DespesaPorCategoriaModel? in

            guard let categoria = itens.first?.categoria else { return nil }

            let total = itens.reduce(Decimal.zero) { total, lancamento in
                total + lancamento.valorDividido
            }

            return DespesaPorCategoriaModel(
                categoria: categoria,
                total: total
            )
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
        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            $0.transferencia == false
        }
        let recorrentes = despesas.filter {
            $0.tipoRecorrente == .mensal || $0.tipoRecorrente == .quinzenal || $0.tipoRecorrente == .semanal
        }

        if !despesas.isEmpty {
            let totalDespesas = despesas.map(\.valor).reduce(0, +)
            let totalRecorrentes = recorrentes.map(\.valor).reduce(0, +)
            let percentual = totalDespesas > 0 ? (totalRecorrentes / totalDespesas) * 100 : 0
            frases.append("🔁 \(String(format: "%.0f", NSDecimalNumber(decimal: percentual).doubleValue))% das despesas foram recorrentes.")
        }
        
        insights = frases
    }
}

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
        formatter.locale = .current
        return formatter.monthSymbols[mes - 1]
    }
}

struct DespesaPorCategoriaModel: Identifiable {
    let id = UUID()
    let categoria: CategoriaModel
    let total: Decimal
}

