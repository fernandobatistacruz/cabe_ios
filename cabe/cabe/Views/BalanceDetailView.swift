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

                if !vm.topGastos.isEmpty {
                    maioresGastosSection
                }
                
                if !vm.insights.isEmpty {
                    insightsView
                }
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
            SummaryCard(title: String(localized: "Receitas"),
                        value: vm.receitasFormatado,
                        color: .green,
            )
            .padding(.trailing, 2)
            .padding(.horizontal, 1)
            
            SummaryCard(title: String(localized: "Despesas"),
                        value: vm.despesasFormatado,
                        color: .red,
            )
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
            
            SummaryCard(title: String(localized: "Saldo"),
                        value: vm.saldoFormatado,
                        color: .purple
            )
            .padding(.trailing, 2)
            .padding(.horizontal, 1)
            
            SummaryCard(title: String(localized: "Percentual de Gastos"),
                        value: vm.percentualGasto,
                        color: .blue
            )
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
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
                    LancamentoRow(lancamento: item, mostrarPagamento: false)
                        .listRowInsets(
                            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                        )
                }
            }
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
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

