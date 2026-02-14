//
//  BuscarView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 26/01/26.
//

import SwiftUI


struct BuscarView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm = BuscarViewModel()
    @StateObject var vmLancamentos: LancamentoListViewModel
    @Binding var searchText: String
    @State private var lancamentoSelecionado: LancamentoModel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                Section {
                    ForEach(vm.resultados) { lancamento in
                        HStack{
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,                               
                                mostrarVencimento: true
                            )
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .listRowInsets(
                            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            lancamentoSelecionado = lancamento
                        }
                    }
                } header: {
                    if !vm.resultados.isEmpty {
                        HStack {
                            Text("Resultados")                               
                            Spacer()
                            Text("\(vm.resultados.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if vm.carregando {
                ProgressView()
            } else if vm.buscou && vm.resultados.isEmpty {
                Group {
                    Text("Nenhum Resultado")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .navigationTitle("Buscar")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText)
        .onChange(of: searchText) { novoValor in
            vm.onTextoChange(novoValor)
        }
        .onAppear {
            vm.recarregarSeNecessario(texto: searchText)
        }
        .sheet(item: $lancamentoSelecionado) { lancamento in
            NavigationStack {
                LancamentoDetalheView(
                    lancamento: lancamento,
                    vmLancamentos: vmLancamentos,
                    isModal: true
                )
            }
        }
    }
}


