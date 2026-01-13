//
//  CategoriaFormView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/01/26.
//

import SwiftUI

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
    @State private var categoriaPai: CategoriaModel?

    // MARK: - Subcategorias
    @State private var subcategorias: [CategoriaModel] = []
    @State private var todasCategorias: [CategoriaModel] = []

    // MARK: - Sheet
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
            ZStack {
                // MARK: - Fundo fixo
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Tipo
                    if !isEditar {
                        Picker("Tipo", selection: $tipoFiltro) {
                            ForEach(Tipo.allCases.reversed(), id: \.self) {
                                Text($0.descricao).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    List {
                        
                        // MARK: - Card Ícone + Nome
                        Section {
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
                                .padding()
                                .background(Color(.systemGroupedBackground))
                                .cornerRadius(22)
                                .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(22)
                        }
                        .listRowInsets(.init())
                        .listRowBackground(Color.clear)
                        
                        // MARK: - Subcategorias
                        if isEditar {
                            Section {
                                if subcategorias.isEmpty {
                                    Text("Nenhuma subcategoria cadastrada")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)

                                } else {
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
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Subcategorias")
                                    Spacer()
                                    Button {
                                        sheetSubcategoria = .nova
                                    } label: {
                                        Image(systemName: "plus")
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Cores
                        if categoriaPai == nil {
                            Section {
                                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                                    ForEach(CorModel.cores, id: \.id) { cor in
                                        Circle()
                                            .fill(cor.cor)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(.gray, lineWidth: cor.id == corSelecionada.id ? 3 : 0)
                                            )
                                            .onTapGesture { corSelecionada = cor }
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(22)
                            } header: {
                                HStack {
                                    Text("Cor")
                                }.padding(.horizontal)
                            }
                            .listRowInsets(.init())
                            .listRowBackground(Color.clear)
                            
                            // MARK: - Ícones
                            Section {
                                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                                    ForEach(IconeModel.icones, id: \.id) { icone in
                                        Image(systemName: icone.systemName)
                                            .frame(width: 32, height: 32)
                                            .padding(8)
                                            .background(
                                                icone.id == iconeSelecionado.id
                                                ? Color(.systemGray4)
                                                : Color.clear
                                            )
                                            .cornerRadius(8)
                                            .onTapGesture { iconeSelecionado = icone }
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(22)
                            } header: {
                                HStack {
                                    Text("Ícone")
                                }.padding(.horizontal)
                            }
                            .listRowInsets(.init())
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
                            if let i = subcategorias.firstIndex(where: { $0.id == sub.id }) {
                                subcategorias[i] = sub
                            } else {
                                subcategorias.append(sub)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Row Subcategoria
    private func subcategoriaRow(_ sub: CategoriaModel) -> some View {
        HStack {
            Circle()
                .fill(corSelecionada.cor)
                .frame(width: 10, height: 10)
            
            Text(sub.nomeSubcategoria ?? sub.nome)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
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

        //TODO: Revisa para quando for editar categoria considerando o nomeKey
        let novaCategoria = CategoriaModel(
            id: novoId,
            nomeRaw: nome,
            tipo: isEditar ? categoria?.tipo ?? 1 : tipoFiltro.rawValue,
            icone: iconeSelecionado.id,
            cor: corSelecionada.id,
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
            nomeRaw: categoriaPai.nome,
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
