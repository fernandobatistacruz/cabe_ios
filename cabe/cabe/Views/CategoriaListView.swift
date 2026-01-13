//
//  CategoriaListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//

import SwiftUI

struct CategoriaListView: View {
    
    @State private var searchText = ""
    @State private var mostrarNovaCategoria = false
    @State private var mostrarConfirmacao = false
    @State private var categoriaParaExcluir: CategoriaModel?
    @State private var tipoFiltro: Tipo = .despesa
    @State private var mostrarEditarCategoria = false
    @State private var categoriaSelecionada: CategoriaModel? = nil
    @StateObject private var viewModel: CategoriaListViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @Environment(\.isSearching) private var isSearching
    
    init() {
        let repository = CategoriaRepository()
        _viewModel = StateObject(
            wrappedValue: CategoriaListViewModel(repository: repository)
        )
    }
    
    var categoriasFiltradas: [CategoriaModel] {
        viewModel.categorias.filter { categoria in
            let matchesSearch = searchText.isEmpty ||
                categoria.nome.localizedCaseInsensitiveContains(searchText)
            let matchesTipo = categoria.tipo == tipoFiltro.rawValue
            let isRootCategory = categoria.pai == nil  //
            return matchesSearch && matchesTipo && isRootCategory
        }
    }
    
    var body: some View {
        VStack {
            Picker("Tipo", selection: $tipoFiltro) {
                ForEach(Tipo.allCases.reversed(), id: \.self) { tipo in
                    Text(tipo.descricao).tag(tipo)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .background(Color(.systemGroupedBackground))
            
            List(categoriasFiltradas) { categoria in
                CategoriaListRow(categoria: categoria)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        categoriaSelecionada = categoria
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            categoriaParaExcluir = categoria
                            mostrarConfirmacao = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
            }
            .sheet(item: $categoriaSelecionada) { categoria in
                NavigationStack {
                    CategoriaFormView(categoria: categoria, isEditar: true)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden) // garante fundo igual ao da view
            .background(Color(.systemGroupedBackground))
            .overlay(
                categoriasFiltradas.isEmpty ?
                    AnyView(
                        Text("Nenhuma categoria encontrada")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    )
                    : AnyView(EmptyView())
            )
        }
        .navigationTitle("Categorias")
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .tabBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Buscar"
        )
        .alert(
            "Excluir categoria?",
            isPresented: $mostrarConfirmacao
        ) {
            Button("Excluir", role: .destructive) {
                if let categoria = categoriaParaExcluir {
                    viewModel.remover(categoria)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Essa ação não poderá ser desfeita.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarNovaCategoria = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarNovaCategoria) {
            NavigationStack {
                if sub.isSubscribed {
                    CategoriaFormView(categoria: nil, isEditar: false)
                } else {
                    PaywallView()
                }
            }
        }
    }
}


// MARK: - Row

struct CategoriaListRow: View {

    let categoria: CategoriaModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoria.getIcone().systemName)
                .frame(width: 24)
                .foregroundColor(categoria.getCor().cor)

            Text(categoria.nome)
                .font(.body)

            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
               
        }
    }
}
