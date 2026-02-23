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

private enum CampoFoco {
    case nome
}

struct CategoriaFormView: View {
    @Environment(\.dismiss) private var dismiss
       
    @State var categoria: CategoriaModel?
    @State var isEditar: Bool
    @State private var nome: String
    @State private var corSelecionada: Color
    @State private var iconeSelecionado: IconeModel
    @State private var tipoFiltro: Tipo
    @State private var categoriaPai: CategoriaModel?
    @State private var subcategorias: [CategoriaModel] = []
    @State private var todasCategorias: [CategoriaModel] = []
    @State private var sheetSubcategoria: SubcategoriaSheetMode?
    @FocusState private var campoFocado: CampoFoco?
    @EnvironmentObject var sub: SubscriptionManager
    @State private var mostrarPaywall = false
    @State private var mostrarAlerta = false
    @State private var mostrarConfirmacao = false
    @State private var categoriaParaExcluir: CategoriaModel?
   
    init(categoria: CategoriaModel? = nil, isEditar: Bool = false) {
        self._categoria = State(initialValue: categoria)
        self._isEditar = State(initialValue: isEditar)
        self._nome = State(initialValue: categoria?.nome ?? "")
        self._corSelecionada = State(initialValue: categoria?.cor ?? .blue)
        self._iconeSelecionado = State(
            initialValue: categoria?.icone ?? IconeModel.icones.first!
        )
        self._tipoFiltro = State(initialValue: categoria.map { Tipo(rawValue: $0.tipo) ?? .despesa } ?? .despesa)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    categoriaPai?.cor.gradient ?? corSelecionada.gradient
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(
                                systemName: categoriaPai?.icone.systemName ?? iconeSelecionado.systemName
                            )
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                        }
                        
                        TextField(
                            categoriaPai == nil ? "Nome da Categoria" : "Nome da Subcategoria",
                            text: $nome
                        )
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(22)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .focused($campoFocado, equals: .nome)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(22)
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
             
                if isEditar {
                    Section {
                        if subcategorias.isEmpty {
                            Text("Nenhuma Subcategoria")
                                .font(.subheadline)
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
                                            Task{
                                                let existe = try await LancamentoRepository()
                                                    .existeLancamentoParaCategoria(
                                                        id: sub.id ?? 0,
                                                        tipo: sub.tipo
                                                    )
                                                if existe {
                                                    mostrarAlerta = true
                                                } else {
                                                    categoriaParaExcluir = sub
                                                    mostrarConfirmacao = true
                                                }
                                            }
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
                                if sub.isSubscribed {
                                    sheetSubcategoria = .nova
                                } else {
                                    mostrarPaywall = true
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Cor")
                    Spacer()
                    ColorPicker("", selection: $corSelecionada)
                }
                              
                if categoriaPai == nil {
                    Section {
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                            ForEach(IconeModel.icones, id: \.id) { icone in
                                Image(systemName: icone.systemName)
                                    .frame(width: 32, height: 32)
                                    .padding(8)
                                    .foregroundColor(icone.id == iconeSelecionado.id
                                                     ? Color.white
                                                     : Color.primary)
                                    .background(
                                        icone.id == iconeSelecionado.id
                                        ? Color.accentColor
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
        .scrollDismissesKeyboard(.immediately)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditar ? "Editar Categoria" : "Nova Categoria")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            if !isEditar {
                Picker("Tipo", selection: $tipoFiltro) {
                    ForEach(Tipo.allCases.reversed(), id: \.self) {
                        Text($0.descricao).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if sub.isSubscribed {
                        Task{
                            await salvar()
                        }
                    } else {
                        mostrarPaywall = true
                    }
                } label: {
                    Image(systemName: "checkmark").foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .disabled(nome.isEmpty)
            }
        }
        .alert("", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Esta subcategoria está um uso e não poderá ser excluída.")
        }
        .alert(
            "Excluir Subcategoria?",
            isPresented: $mostrarConfirmacao
        ) {
            Button("Excluir", role: .destructive) {
                Task {
                    guard let categoria = categoriaParaExcluir else { return }
                    await removerSubcategoria(categoria)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Essa ação não poderá ser desfeita.")
        }
        .onAppear {
            todasCategorias = try! CategoriaRepository().listar()
            if let cat = categoria, isEditar {
                subcategorias = todasCategorias.filter { $0.pai == cat.id }
            }
            if !isEditar{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    campoFocado = .nome
                }
            }
        }
        .sheet(isPresented: $mostrarPaywall) {
            NavigationStack {
                PaywallView()
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
  
    private func subcategoriaRow(_ sub: CategoriaModel) -> some View {
        HStack {
            Circle()
                .fill(corSelecionada)
                .frame(width: 10, height: 10)
            
            Text(sub.nomeSubcategoria ?? sub.nome)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    private func removerSubcategoria (_ sub: CategoriaModel) async {
        try? await CategoriaRepository().remover(id: sub.id ?? 0, tipo: sub.tipo)
        subcategorias.removeAll { $0.id == sub.id }
    }
  
    private func salvar() async {
        let proximoId: Int64 = (try! CategoriaRepository()
            .listar()
            .compactMap { $0.id }
            .max() ?? 0) + 1

        let novoId: Int64 = isEditar ? categoria?.id ?? proximoId : proximoId

        //TODO: Revisa para quando for editar categoria considerando o nomeKey
        let comp = corSelecionada.components()
        
        let novaCategoria = CategoriaModel(
            id: novoId,
            nomeRaw: nome,
            tipo: isEditar ? categoria?.tipo ?? 1 : tipoFiltro.rawValue,
            iconeRaw: iconeSelecionado.id,
            red: comp.red,
            green: comp.green,
            blue: comp.blue,
            opacity: comp.opacity,
        )

        do {
            if isEditar {
                let repository = CategoriaRepository()
                try await repository.editar(novaCategoria)
                
                subcategorias = subcategorias.map { categoria in
                    var nova = categoria
                    nova.red = novaCategoria.red
                    nova.green = novaCategoria.green
                    nova.blue = novaCategoria.blue
                    nova.opacity = novaCategoria.opacity
                    nova.iconeRaw = iconeSelecionado.id
                    return nova
                }
                
                try await repository.editarSubcategorias(subcategorias)
            } else {
                try await CategoriaRepository().salvar(novaCategoria)
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
                    TextField("Nome da Subcategoria", text: $nome)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle(subcategoria == nil ? "Nova Subcategoria" : "Editar Subcategoria")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
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
                            await salvar()
                        }
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

    private func salvar() async {
        let id: Int64 = subcategoria?.id ??
            ((try! CategoriaRepository().listar()
                .compactMap { $0.id }
                .max() ?? 0) + 1)
        
        

        let nova = CategoriaModel(
            id: id,
            nomeRaw: categoriaPai.nome,
            nomeSubcategoria: nome,
            tipo: categoriaPai.tipo,
            iconeRaw: categoriaPai.iconeRaw,
            red: categoriaPai.red,
            green: categoriaPai.green,
            blue: categoriaPai.blue,
            opacity: categoriaPai.opacity,
            pai: categoriaPai.id
        )

        do {
            if subcategoria == nil {
                try await CategoriaRepository().salvar(nova)
            } else {
                try await CategoriaRepository().editar(nova)
            }
            onSalvar(nova)
            dismiss()
        } catch {
            debugPrint("Erro ao salvar subcategoria", error)
        }
    }
}
