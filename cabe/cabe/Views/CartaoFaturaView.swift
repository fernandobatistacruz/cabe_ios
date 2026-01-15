//
//  CartaoFaturaView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//

import SwiftUI

struct CartaoFaturaView: View {
    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]
    let total: Decimal
    let vencimento: Date
    
    @State private var searchText = ""
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    
    var filtroLancamentos: [LancamentoModel] {
        searchText.isEmpty
        ? lancamentos
        : lancamentos
            .filter {
                $0.descricao.localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        List {
            HStack(spacing: 16) {
                Image(cartao.operadoraEnum.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cartao.nome)
                        .font(.title3.bold())
                    Text(vencimento.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(
                    total,
                    format:
                        .currency(
                            code: lancamentos.first?.currencyCode ?? "USD"
                        )
                )
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            }
            if(!filtroLancamentos.isEmpty) {
                Section("Entries") {
                    ForEach(filtroLancamentos) { lancamento in
                        NavigationLink {
                            LancamentoDetalheView(lancamento: lancamento)
                        } label: {
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,
                                mostrarValores: true
                            )
                        }
                    }
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
                }
            }
            
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Fatura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Buscar", text: $searchText)
                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .clipShape(Capsule())
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button{
                    print("Filtro")
                    
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                Menu {
                    Button {
                        print("Ação")
                    } label: {
                        Label("Conferência de Fatura", systemImage: "doc.text.magnifyingglass")
                    }
                    Button {
                        Task {
                            await exportarCSV()
                        }
                       
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("Exportar Fatura", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)                    
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .overlay(
            Group {
                if filtroLancamentos.isEmpty {
                    Text("Nenhum lançamento encontrado")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        )
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.url])
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
    
    private func exportarCSV() async {
        guard !isExporting else { return }

        isExporting = true

        defer { isExporting = false }

        do {
            let url = try await ExportarLancamentos.export(
                lancamentos: lancamentos,
                fileName: "lancamentos_fatura.csv"
            )

            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }
}
