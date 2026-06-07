//
//  CategoriaMoverView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 07/06/26.
//

import SwiftUI

struct CategoriaMoverView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var mostrarZoomCategoria = false
    @State private var tipoFiltro: Tipo = .despesa
    @State private var categoriaOrigem: CategoriaModel?
    @State private var categoriaDestino: CategoriaModel?
    @State private var showZoomOrigem: Bool = false
    @State private var showZoomDestino: Bool = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack{
            List {
                Section {
                    Button {
                        showZoomOrigem = true
                    } label: {
                        HStack {
                            Text("Categoria de Origem")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            let nome = categoriaOrigem?.pai == nil
                            ? categoriaOrigem?.nome ?? String(
                                localized: "Selecione"
                            )
                            : categoriaOrigem?.nomeSubcategoria ?? String(localized: "Selecione")
                            
                            Text(nome)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                }
                Section {
                    Button {
                        showZoomDestino = true
                    } label: {
                        HStack {
                            Text("Categoria de Destino")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            let nome = categoriaDestino?.pai == nil
                            ? categoriaDestino?.nome ?? String(
                                localized: "Selecione"
                            )
                            : categoriaDestino?.nomeSubcategoria ?? String(localized: "Selecione")
                            
                            Text(nome)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .top) {
                Picker("Tipo", selection: $tipoFiltro) {
                    ForEach(Tipo.allCases.reversed(), id: \.self) { tipo in
                        Text(tipo.descricao).tag(tipo)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: tipoFiltro) { novoValor in
                    categoriaOrigem = nil
                    categoriaDestino = nil
                }
            }
            .navigationTitle("Mover Lançamentos")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showZoomOrigem) {
                NavigationStack {
                    ZoomCategoriaView(
                        categoriaSelecionada: $categoriaOrigem,
                        tipo: tipoFiltro
                    )
                }
            }
            .sheet(isPresented: $showZoomDestino) {
                NavigationStack {
                    ZoomCategoriaView(
                        categoriaSelecionada: $categoriaDestino,
                        tipo: tipoFiltro
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task{
                            isSaving = true

                            defer {
                                isSaving = false
                            }

                            do {
                                try await LancamentoRepository()
                                    .transferirCategoria(
                                        tipo: tipoFiltro.rawValue,
                                        categoriaOrigemID: categoriaOrigem?.id ?? 0,
                                        categoriaDestinoID: categoriaDestino?.id ?? 0
                                    )

                                dismiss()

                            } catch {
                                print("Erro ao transferir categoria:", error)
                            }
                        }
                       
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(categoriaOrigem == nil || categoriaDestino == nil)
                }
            }
            .overlay {
                if isSaving {
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
}
