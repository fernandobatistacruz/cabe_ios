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
            .filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
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
                            Image(systemName: categoria.getIcone().systemName)
                                .frame(width: 24)
                                .foregroundColor(categoria.getCor().cor)

                            Text(categoria.nome)
                                .foregroundColor(.primary)
                            
                        } else {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .frame(width: 24)
                                .foregroundColor(categoria.getCor().cor)

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
        .onAppear {
            guard categorias.isEmpty else { return }
            categorias = (try? repository.listar(tipo: tipo)) ?? []
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
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
    }
    
    private func isSelecionada(_ categoria: CategoriaModel) -> Bool {
        categoriaSelecionada?.id == categoria.id &&
        categoriaSelecionada?.tipo == categoria.tipo
    }
}

