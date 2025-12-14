//
//  LancamentosView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/12/25.
//

import SwiftUI
internal import Combine


struct LancamentosView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                LancamentosListView()
            }
            .navigationTitle("Dezembro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        print("Leading tap")
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("2025")
                        
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        print("Add")
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button {
                        print("Mais")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
    }
}

#Preview {
    LancamentosView().environmentObject(ThemeManager())
}

struct LancamentoItem: Identifiable {
    let id = UUID()
    let descricao: String
    let valor: Double
    let data: Date
    let icone: String
}

final class LancamentosViewModel: ObservableObject {

    @Published var grupos: [(data: Date, itens: [LancamentoItem])] = []

    init() {
        carregarDados()
    }

    private func carregarDados() {
        let lista = [
            LancamentoItem(descricao: "Supermercado", valor: -120, data: Date(), icone: "cart"),
            LancamentoItem(descricao: "Uber", valor: -25, data: Date(), icone: "car"),
            LancamentoItem(descricao: "Salário", valor: 3500, data: Date().addingTimeInterval(-86400), icone: "banknote")
        ]

        let agrupado = Dictionary(grouping: lista) {
            Calendar.current.startOfDay(for: $0.data)
        }

        grupos = agrupado
            .map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }
}

struct LancamentoRow: View {

    let item: LancamentoItem

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: item.icone)
                .font(.title3)
                .foregroundStyle(.tint)

            VStack(alignment: .leading) {
                Text(item.descricao)
                Text(item.data, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.valor, format: .currency(code: "BRL"))
                .foregroundStyle(.gray)
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
    }
}

struct LancamentosListView: View {

    @StateObject private var viewModel = LancamentosViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.grupos, id: \.data) { grupo in
                    Section {
                        ForEach(grupo.itens) { item in
                            LancamentoRow(item: item)
                                .swipeActions(edge: .leading) {
                                    Button(role: .confirm) {
                                        print("Pago")
                                    } label: {
                                        Label("Pago", systemImage: "doc")
                                    }.tint(.blue)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        print("Excluir")
                                    } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                }
                                
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
                                )
                        }
                    } header: {
                        Text(grupo.data, format: .dateTime.day().month().year())
                    }
                }
            }
            .navigationTitle("Lançamentos")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    LancamentosListView()
}






