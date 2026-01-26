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
    @ObservedObject var vmLancamentos: LancamentoListViewModel
    
    init(vmLancamentos: LancamentoListViewModel) {
        self.vmLancamentos = vmLancamentos
    }
    
    @FocusState private var campoBuscaFocado: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
               
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                
                List(vm.resultados) { lancamento in
                    NavigationLink {
                        LancamentoDetalheView(
                            lancamento: lancamento,
                            vmLancamentos: vmLancamentos
                        )
                    } label: {
                        LancamentoRow(
                            lancamento: lancamento,
                            mostrarPagamento: false,
                            mostrarValores: true
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .overlay {
                    if vm.carregando {
                        ProgressView()
                    } else if vm.buscou && vm.resultados.isEmpty {
                        Group {
                            Text("Nenhum Resultado")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    campoBuscaFocado = true
                }
            }
            .onChange(of: vm.texto) { novoValor in
                vm.onTextoChange(novoValor)
            }
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Buscar", text: $vm.texto)
                            .focused($campoBuscaFocado)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .clipShape(Capsule())
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    campoBuscaFocado = true
                }

                vm.recarregarSeNecessario()
            }
        }
    }
}
