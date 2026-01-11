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

enum SubcategoriaSheetMode: Identifiable {
    case nova
    case editar(CategoriaModel)

    var id: String {
        switch self {
        case .nova:
            return "nova"
        case .editar(let sub):
            return "editar-\(sub.id ?? 0)"
        }
    }
}

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

    // MARK: - Categoria selecionada para editar
    @State private var sheetSubcategoria: SubcategoriaSheetMode?

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
                    // MARK: - Subcategorias (somente edição de categoria)
                    // MARK: - Subcategorias (somente edição de categoria)
                    if isEditar {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Subcategorias")
                                    .font(.headline)

                                Spacer()

                                Button {
                                    sheetSubcategoria = .nova
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                            .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(subcategorias) { sub in
                                    subcategoriaRow(sub)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            sheetSubcategoria = .editar(sub)
                                        }
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                removerSubcategoria(sub)
                                            } label: {
                                                Label("Excluir", systemImage: "trash")
                                            }
                                        }

                                    // Divider padrão iOS
                                    if sub.id != subcategorias.last?.id {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(22)
                            .padding(.horizontal)
                        }
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
            .sheet(item: $sheetSubcategoria) { mode in
                SubcategoriaSheet(
                    categoriaPai: categoria!,
                    subcategoria: {
                        if case let .editar(sub) = mode { return sub }
                        return nil
                    }(),
                    onSalvar: { sub in
                        if let index = subcategorias.firstIndex(where: { $0.id == sub.id }) {
                            subcategorias[index] = sub
                        } else {
                            subcategorias.append(sub)
                        }
                    }
                )
            }
        }
    }
    
    private func subcategoriaRow(_ sub: CategoriaModel) -> some View {
        HStack {
            Circle()
                .fill(sub.getCor().cor)
                .frame(width: 10, height: 10)
            
            Text(sub.nomeSubcategoria ?? sub.nome)
            
            Spacer()
        }.padding()
    }
    
    private func removerSubcategoria(_ sub: CategoriaModel) {
        try? CategoriaRepository().remover(id: sub.id ?? 0, tipo: sub.tipo)
        subcategorias.removeAll { $0.id == sub.id }
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
}

struct SubcategoriaSheet: View {
    @Environment(\.dismiss) private var dismiss

    let categoriaPai: CategoriaModel
    let subcategoria: CategoriaModel?
    let onSalvar: (CategoriaModel) -> Void

    @State private var nome: String

    init(
        categoriaPai: CategoriaModel,
        subcategoria: CategoriaModel?,
        onSalvar: @escaping (CategoriaModel) -> Void
    ) {
        self.categoriaPai = categoriaPai
        self.subcategoria = subcategoria
        self.onSalvar = onSalvar
        _nome = State(initialValue: subcategoria?.nomeSubcategoria ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome da subcategoria", text: $nome)
                }
            }
            .navigationTitle(subcategoria == nil ? "Nova Subcategoria" : "Editar Subcategoria")
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
        let id: Int64 = subcategoria?.id ??
            ((try! CategoriaRepository().listar()
                .compactMap { $0.id }
                .max() ?? 0) + 1)

        let nova = CategoriaModel(
            id: id,
            nome: categoriaPai.nome,
            nomeSubcategoria: nome,
            tipo: categoriaPai.tipo,
            icone: categoriaPai.icone,
            cor: categoriaPai.cor,
            pai: categoriaPai.id
        )

        do {
            if subcategoria == nil {
                try CategoriaRepository().salvar(nova)
            } else {
                try CategoriaRepository().editar(nova)
            }
            onSalvar(nova)
            dismiss()
        } catch {
            debugPrint("Erro ao salvar subcategoria", error)
        }
    }
}
