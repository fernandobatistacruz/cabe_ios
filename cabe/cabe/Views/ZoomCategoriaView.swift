//
//  CategoriaZoomView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//
import SwiftUI

struct ZoomCategoriaView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var categoriaSelecionada: CategoriaModel?
    @State private var searchText = ""

    let tipo: Tipo

    @State private var categorias: [CategoriaModel] = []

    private let repository = CategoriaRepository()
    
    var categoriasFiltradas: [CategoriaModel] {
        searchText.isEmpty
        ? categorias
        : categorias
            .filter { $0.nome.localizedCaseInsensitiveContains(searchText) ||
                ($0.nomeSubcategoria?.localizedCaseInsensitiveContains(searchText)) ?? false
            }
    }

    var body: some View {
        List {
            ForEach(Array(categoriasFiltradas.enumerated()), id: \.offset) { _, categoria in
                Button {
                    categoriaSelecionada = categoria
                    dismiss()
                } label: {
                    HStack {
                        if categoria.pai == nil {
                            Image(systemName: categoria.icone.systemName)
                                .frame(width: 22, height: 22)
                                .foregroundColor(categoria.cor)

                            Text(categoria.nome)
                                .foregroundColor(.primary)
                            
                        } else {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .frame(width: 22, height: 22)
                                .foregroundColor(categoria.cor)

                            Text(categoria.nomeSubcategoria ?? "")
                                .foregroundColor(.primary)
                            
                        }
                        
                        Spacer()

                        if isSelecionada(categoria) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Categorias")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .background(Color(.systemGroupedBackground))
        .scrollContentBackground(.hidden)
        .onAppear {
            guard categorias.isEmpty else { return }
            categorias = (try? repository.listar(tipo: tipo)) ?? []
        }
        .overlay(
            Group {
                if categoriasFiltradas.isEmpty {
                    Text("Nenhuma Categoria")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
            }
        )
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Buscar"
        )
        .toolbar {
            if #available(iOS 26.0, *) {
                DefaultToolbarItem(
                    kind: .search,
                    placement: .bottomBar
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
        }
    }
    
    private func isSelecionada(_ categoria: CategoriaModel) -> Bool {
        categoriaSelecionada?.id == categoria.id &&
        categoriaSelecionada?.tipo == categoria.tipo
    }
}

