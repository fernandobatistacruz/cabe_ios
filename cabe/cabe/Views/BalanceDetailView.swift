//
//  BalanceDetailView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 05/02/26.
//


import SwiftUI

// MARK: - VIEW

struct BalanceDetailView: View {

    @StateObject private var vm: BalanceDetailViewModel

    init(lancamentosMes: [LancamentoModel]) {
        _vm = StateObject(
            wrappedValue: BalanceDetailViewModel(
                lancamentos: lancamentosMes              
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                resumoCards

                maioresGastosSection

                insightsView
            }
            .padding()
        }
        .navigationTitle("Balanço")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

extension BalanceDetailView {

    private var resumoCards: some View {
        LazyVGrid(columns: [.init(), .init()]) {
            SummaryCard(title: "Receitas",
                        value: vm.receitasFormatado,
                        color: .green,
            )
            
            SummaryCard(title: "Despesas",
                        value: vm.despesasFormatado,
                        color: .red,
            )
            
            SummaryCard(title: "Saldo",
                        value: vm.saldoFormatado,
                        color: .purple
            )
            
            SummaryCard(title: "Percentual de Gasto",
                        value: vm.percentualGasto,
                        color: .blue
            )
        }
    }

    private var maioresGastosSection: some View {
        VStack (alignment: .leading) {
            Text("Maiores Gastos")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(vm.topGastos) { item in
                    HStack {
                        Text(item.descricao)
                            .font(.callout)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(item.valorFormatado)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    var insightsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Análises")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ForEach(vm.insights.indices, id: \.self) { index in
                let texto = vm.insights[index]
                InsightRowView(texto: texto)
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

