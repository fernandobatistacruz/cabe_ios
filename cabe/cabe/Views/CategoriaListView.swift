//
//  CategoriaListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//

import SwiftUI
import GRDB
import Combine

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
    
    var categoriasFiltrados: [CategoriaModel] {
        viewModel.categorias.filter { categoria in
            let matchesSearch = searchText.isEmpty ||
                categoria.nome.localizedCaseInsensitiveContains(searchText)
            
            let matchesTipo = categoria.tipo == tipoFiltro.rawValue
            
            return matchesSearch && matchesTipo
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
            
            List(categoriasFiltrados) { categoria in
                Button {
                    categoriaSelecionada = categoria
                } label: {
                    CategoriaListRow(categoria: categoria)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                categoriaParaExcluir = categoria
                                mostrarConfirmacao = true
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                        }
                }
               .buttonStyle(.plain) // mantém estilo de List row
            }
            .sheet(item: $categoriaSelecionada) { categoria in
                NavigationStack {
                    EditarCategoriaView(categoria: categoria)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden) // garante fundo igual ao da view
            .background(Color(.systemGroupedBackground))
            .overlay(
                categoriasFiltrados.isEmpty ?
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
                    NovaCategoriaView()
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

// MARK: - Nova Categoria

struct NovaCategoriaView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var nome: String = ""
    @State private var saldoText: String = ""
    @State private var saldoDecimal: Decimal? = nil


    var body: some View {
        Form {
            TextField("Nome", text: $nome)
            
            TextField("Saldo", text: $saldoText)
                .keyboardType(.decimalPad)
                .onChange(of: saldoText) { value in
                    saldoDecimal = NumberFormatter.decimalInput
                        .number(from: value) as? Decimal
                }
            
        }
        .navigationTitle("Nova Conta")
        .navigationBarTitleDisplayMode(.inline)
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
                    salvar()
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(nome.isEmpty || saldoDecimal == nil)
            }
        }
    }
    

    private func salvar() {
        
        var conta = ContaModel.init(
            uuid: UUID().uuidString,
            nome: nome,
            saldo: NSDecimalNumber(decimal: saldoDecimal ?? 0).doubleValue,
            currencyCode : Locale.current.currency?.identifier ?? "BRL"
        )
        
        do {
            try ContaRepository().salvar(&conta)
        }
        catch{
            debugPrint("Erro ao editar conta", error)
        }
        
        dismiss()
    }
}


// MARK: - Editar Categoria

import SwiftUI

struct EditarCategoriaView: View {
    @Environment(\.dismiss) private var dismiss

    @State var categoria: CategoriaModel

    @State private var nome: String = ""
    @State private var corSelecionada: CorModel
    @State private var iconeSelecionado: IconeModel

    init(categoria: CategoriaModel) {
        self._categoria = State(initialValue: categoria)
        self._nome = State(initialValue: categoria.nome)
        self._corSelecionada = State(initialValue: categoria.getCor())
        self._iconeSelecionado = State(initialValue: categoria.getIcone())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Card com ícone e nome
                    // Card com ícone e campo de nome editável
                    VStack(spacing: 16) {
                        // Ícone principal com cor
                        ZStack {
                            Circle()
                                .fill(corSelecionada.cor)
                                .frame(width: 80, height: 80)
                            Image(systemName: iconeSelecionado.systemName)
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }

                        // Campo de nome editável
                        TextField("Nome da categoria", text: $nome)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(22)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center) // centraliza o texto
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal) // padding externo do card

                    // Seleção de cores
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cores")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(CorModel.cores, id: \.id) { cor in
                                Circle()
                                    .fill(cor.cor)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color(.systemGray),
                                                lineWidth: cor.id == corSelecionada.id ? 4 : 0
                                            )
                                    )
                                    .onTapGesture {
                                        corSelecionada = cor
                                    }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                    }
                    .padding(.horizontal)

                    // Seleção de ícones
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ícones")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(IconeModel.icones, id: \.id) { icone in
                                Image(systemName: icone.systemName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .padding(8)
                                    .background(
                                        icone.id == iconeSelecionado.id ? Color(
                                            .systemGray
                                        ) : Color.clear
                                    )
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        iconeSelecionado = icone
                                    }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal)

                }
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden) // garante que ScrollView respeite o fundo
            .navigationTitle("Editar Categoria")
            .navigationBarTitleDisplayMode(.inline)
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
                        salvar()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(nome.isEmpty)
                }
            }
        }
    }

    private func salvar() {
        categoria.nome = nome
        categoria.cor = corSelecionada.id
        categoria.icone = iconeSelecionado.id

        do {
            try CategoriaRepository().editar(categoria)
        } catch {
            debugPrint("Erro ao editar categoria", error)
        }

        dismiss()
    }
}
