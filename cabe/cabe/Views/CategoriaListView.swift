//
//  CategoriaListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//

import SwiftUI

struct CategoriaListView: View {
    
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var mostrarNovaCategoria = false
    @State private var mostrarConfirmacao = false
    @State private var mostrarAlerta = false
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
            
            List(categoriasFiltradas) { categoria in
                CategoriaListRow(categoria: categoria)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        categoriaSelecionada = categoria
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            categoriaParaExcluir = categoria
                           
                            Task {
                                let existe = try await LancamentoRepository()
                                    .existeLancamentoParaCategoria(
                                        id: categoria.id ?? 0,
                                        tipo: categoria.tipo
                                    )
                                if existe {
                                    mostrarAlerta = true
                                } else {
                                    mostrarConfirmacao = true
                                }
                            }
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
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden) // garante fundo igual ao da view
            .background(Color(.systemGroupedBackground))
            .overlay(
                Group {
                    if categoriasFiltradas.isEmpty {
                        Text("Nenhuma Categoria")
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)                        
                    }
                }
            )
        }
        .navigationTitle("Categorias")
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .tabBar)
        .alert("", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Esta categoria está um uso e não poderá ser excluída.")
        }
        .alert(
            "Excluir Categoria?",
            isPresented: $mostrarConfirmacao
        ) {
            Button("Excluir", role: .destructive) {
                Task{
                    if let categoria = categoriaParaExcluir {
                        await viewModel.remover(categoria)
                    }
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
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar", text: $searchText)
                        .focused($searchFocused)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .clipShape(Capsule())
                
                if !searchText.isEmpty {
                    Spacer()
                    Button {
                        searchText = ""                       
                        UIApplication.shared.endEditing()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(searchText.isEmpty)
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
