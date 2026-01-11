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
                    .contentShape(Rectangle()) // faz toda a row "clicável"
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

struct CategoriaFormView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Inputs
    @State var categoria: CategoriaModel?
    @State var isEditar: Bool

    // MARK: - Campos do Form
    @State private var nome: String
    @State private var corSelecionada: CorModel
    @State private var iconeSelecionado: IconeModel
    @State private var tipoFiltro: Tipo
    @State private var categoriaPai: CategoriaModel? // para subcategoria

    // MARK: - Subcategorias
    @State private var subcategorias: [CategoriaModel] = []
    @State private var todasCategorias: [CategoriaModel] = []

    // MARK: - Sheet subcategoria
    @State private var mostrarSheetSubcategoria: Bool = false
    @State private var nomeNovaSubcategoria: String = ""

    // MARK: - Categoria selecionada para editar
    @State private var categoriaSelecionadaParaEdicao: CategoriaModel?

    // MARK: - Init
    init(categoria: CategoriaModel? = nil, isEditar: Bool = false) {
        self._categoria = State(initialValue: categoria)
        self._isEditar = State(initialValue: isEditar)
        self._nome = State(initialValue: categoria?.nome ?? "")
        self._corSelecionada = State(initialValue: categoria?.getCor() ?? CorModel.cores.first!)
        self._iconeSelecionado = State(initialValue: categoria?.getIcone() ?? IconeModel.icones.first!)
        self._tipoFiltro = State(initialValue: categoria.map { Tipo(rawValue: $0.tipo) ?? .despesa } ?? .despesa)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Tipo (somente se não tem pai e não é edição)
                    if categoriaPai == nil && !isEditar {
                        Picker("Tipo", selection: $tipoFiltro) {
                            ForEach(Tipo.allCases.reversed(), id: \.self) { tipo in
                                Text(tipo.descricao).tag(tipo)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                  

                    // MARK: - Card ícone + nome
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(categoriaPai?.getCor().cor ?? corSelecionada.cor)
                                .frame(width: 80, height: 80)
                            Image(systemName: categoriaPai?.getIcone().systemName ?? iconeSelecionado.systemName)
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }

                        TextField(
                            categoriaPai == nil ? "Nome da categoria" : "Nome da subcategoria",
                            text: $nome
                        )
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(22)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // MARK: - Subcategorias (somente edição de categoria)
                    if isEditar {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Subcategorias").bold()
                                Spacer()
                                Button(action: {
                                    nomeNovaSubcategoria = ""
                                    mostrarSheetSubcategoria = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                }
                            }
                            .padding(.horizontal)

                            ForEach(subcategorias) { sub in
                                HStack {
                                    Circle()
                                        .fill(sub.getCor().cor)
                                        .frame(width: 12, height: 12)
                                    Text(sub.nomeSubcategoria ?? sub.nome)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    categoriaSelecionadaParaEdicao = sub
                                    nome = sub.nomeSubcategoria ?? sub.nome
                                    corSelecionada = sub.getCor()
                                    iconeSelecionado = sub.getIcone()
                                    tipoFiltro = Tipo(rawValue: sub.tipo) ?? .despesa
                                    categoriaPai = todasCategorias.first { $0.id == sub.pai }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 12)
                    }

                    // MARK: - Seleção de cores e ícones (somente se não for subcategoria)
                    if categoriaPai == nil {
                        // Cores
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(CorModel.cores, id: \.id) { cor in
                                Circle()
                                    .fill(cor.cor)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemGray), lineWidth: cor.id == corSelecionada.id ? 4 : 0)
                                    )
                                    .onTapGesture { corSelecionada = cor }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .padding(.horizontal)

                        // Ícones
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(IconeModel.icones, id: \.id) { icone in
                                Image(systemName: icone.systemName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .padding(8)
                                    .background(icone.id == iconeSelecionado.id ? Color(.systemGray) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture { iconeSelecionado = icone }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .navigationTitle(isEditar ? "Editar Categoria" : "Nova Categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { salvar() } label: {
                        Image(systemName: "checkmark").foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(nome.isEmpty)
                }
            }
            .onAppear {
                todasCategorias = try! CategoriaRepository().listar()
                if let cat = categoria, isEditar {
                    subcategorias = todasCategorias.filter { $0.pai == cat.id }
                }
            }
            .sheet(isPresented: $mostrarSheetSubcategoria) {
                NavigationStack {
                    ZStack {
                        Color(uiColor: .systemGroupedBackground)
                            .ignoresSafeArea()

                        VStack(spacing: 24) {
                            Form {
                                Section{
                                    TextField("Nome", text: $nomeNovaSubcategoria)
                                }
                            }
                        }
                    }
                    .navigationTitle("Nova Subcategoria")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                mostrarSheetSubcategoria = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                salvarSubcategoria()
                                mostrarSheetSubcategoria = false
                            } label: {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .disabled(nomeNovaSubcategoria.isEmpty)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Salvar categoria principal
    private func salvar() {
        let proximoId: Int64 = (try! CategoriaRepository()
            .listar()
            .compactMap { $0.id }
            .max() ?? 0) + 1

        let novoId: Int64 = isEditar ? categoria?.id ?? proximoId : proximoId

        let novaCategoria = CategoriaModel(
            id: novoId,
            nome: categoriaPai == nil ? nome : categoria?.nome ?? "",
            nomeSubcategoria: categoriaPai == nil ? nil : nome,
            tipo: categoriaPai?.tipo ?? (isEditar ? categoria?.tipo ?? 1 : tipoFiltro.rawValue),
            icone: categoriaPai?.icone ?? iconeSelecionado.id,
            cor: categoriaPai?.cor ?? corSelecionada.id,
            pai: categoriaPai?.id
        )

        do {
            if isEditar {
                try CategoriaRepository().editar(novaCategoria)
            } else {
                try CategoriaRepository().salvar(novaCategoria)
            }
            self.categoria = novaCategoria
        } catch {
            debugPrint("Erro ao salvar categoria", error)
        }

        dismiss()
    }

    // MARK: - Salvar subcategoria
    private func salvarSubcategoria() {
        guard let pai = categoria else { return }

        let proximoId: Int64 = (try! CategoriaRepository().listar()
            .compactMap { $0.id }
            .max() ?? 0) + 1

        let novaSub = CategoriaModel(
            id: proximoId,
            nome: pai.nome, // mantém nome da categoria pai
            nomeSubcategoria: nomeNovaSubcategoria,
            tipo: pai.tipo,
            icone: pai.icone,
            cor: pai.cor,
            pai: pai.id
        )

        do {
            try CategoriaRepository().salvar(novaSub)
            subcategorias.append(novaSub)
        } catch {
            debugPrint("Erro ao salvar subcategoria", error)
        }
    }
}
