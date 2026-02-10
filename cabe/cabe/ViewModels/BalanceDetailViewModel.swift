//
//  BalanceDetailViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/02/26.
//


import Foundation
import SwiftUI
import Combine

final class BalanceDetailViewModel: ObservableObject {
    
    let lancamentos: [LancamentoModel]
    
    init(lancamentos: [LancamentoModel]) {
        self.lancamentos = lancamentos
    }

    // MARK: Totais

    var receitas: Decimal {
        lancamentos.filter { $0.tipo == Tipo.receita.rawValue }
            .reduce(0) { $0 + $1.valorParaSaldo }
    }

    var despesas: Decimal {
        lancamentos.filter { $0.tipo == Tipo.despesa.rawValue }
            .reduce(0) { $0 + $1.valorParaSaldo }
    }

    var saldo: Decimal {
        receitas - despesas
    }

    // MARK: Formatação

    private func currency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f.string(for: value as NSDecimalNumber) ?? "-"
    }

    var receitasFormatado: String { currency(receitas) }
    var despesasFormatado: String { currency(despesas) }
    var saldoFormatado: String { currency(saldo) }

    var percentualGasto: String {
        guard receitas > 0 else { return "—" }

        let r = NSDecimalNumber(decimal: receitas).doubleValue
        let d = NSDecimalNumber(decimal: despesas).doubleValue

        let percent = (d / r) * 100

        return String(format: "%.0f%%", percent)
    }

    // MARK: Categoria

    struct CategoriaValor: Identifiable {
        let id = UUID()
        let nome: String
        let valor: Decimal
    }
    
    var despesasPorCategoria: [CategoriaValor] {
        let despesas = lancamentos.filter { $0.tipo == Tipo.despesa.rawValue }
        
        let grouped = Dictionary(grouping: despesas) {
            $0.categoria?.nome ?? "Outros"
        }
        
        return grouped.map {
            CategoriaValor(
                nome: $0.key,
                valor: abs($0.value.reduce(0) { $0 + $1.valorParaSaldo })
            )
        }
        .sorted { $0.valor > $1.valor }
    }

    

    // MARK: Comparação

    private func totalReceita(_ arr: [LancamentoModel]) -> Decimal {
        arr.filter { $0.tipo == Tipo.receita.rawValue }
            .reduce(0) { $0 + $1.valorParaSaldo }
    }

    private func totalDespesa(_ arr: [LancamentoModel]) -> Decimal {
        arr.filter { $0.tipo == Tipo.despesa.rawValue }
            .reduce(0) { $0 + $1.valorParaSaldo }
    }

    private func percentualVariacao(atual: Decimal, anterior: Decimal) -> Double {
        guard anterior != 0 else { return 0 }
        return ((atual - anterior) / anterior as NSDecimalNumber).doubleValue * 100
    }

    // MARK: Top gastos

    struct GastoItem: Identifiable {
        let id = UUID()
        let descricao: String
        let valor: Decimal
      
        var valorFormatado: String {
            let f = NumberFormatter()
            f.numberStyle = .currency
            return f.string(for: valor as NSDecimalNumber) ?? "-"
        }
    }

    var topGastos: [GastoItem] {
        lancamentos
            .filter { $0.valorComSinal < 0 }
            .sorted { $0.valorComSinal < $1.valorComSinal }
            .prefix(5)
            .map {
                GastoItem(
                    descricao: $0.descricao,
                    valor: abs($0.valorComSinal)
                )
            }
    }

    // MARK: Insights
    
    var insights: [LocalizedStringKey] {

        var frases: [LocalizedStringKey] = []

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
        
        if saldo > 0 {
            frases.append("💵 Você economizou \(saldoFormatado) este mês.")
        }
        
        if self.despesas > receitas * 0.9 {
            frases.append("⚠️ Atenção, você gastou quase toda a sua renda.")
        }
        
        return frases
    }

}
