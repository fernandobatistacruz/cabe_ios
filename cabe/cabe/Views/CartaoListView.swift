//
//  CartoesListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI
import GRDB
import Combine

struct CartaoListView: View {
    
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var mostrarNovoCartao = false
    @State private var mostrarConfirmacao = false
    @State private var mostrarAlerta = false
    @State private var cartaoParaExcluir: CartaoModel?
    @State private var filtroSelecionado: FiltroCartao = .ativos
    @StateObject private var viewModel: CartaoListViewModel
    @EnvironmentObject var sub: SubscriptionManager
    @Environment(\.isSearching) private var isSearching
    
    init() {
        let repository = CartaoRepository()
        _viewModel = StateObject(
            wrappedValue: CartaoListViewModel(repository: repository)
        )
    }
    
    var cartoesFiltrados: [CartaoModel] {
        viewModel.cartoes
            .filter { cartao in
                cartao.arquivado == filtroSelecionado.valorArquivado
            }
            .filter { cartao in
                searchText.isEmpty
                || cartao.nome.localizedCaseInsensitiveContains(searchText)
            }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(cartoesFiltrados) { cartao in
                    NavigationLink(
                        destination: CartaoDetalheView(cartao: cartao)
                    ) {
                        CartaoRow(cartao: cartao)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    Task{
                                        await viewModel.toggleArquivado([cartao])
                                    }
                                } label: {
                                    Label(cartao.arquivado ? String(localized: "Desarquivar") : String(localized: "Arquivar"), systemImage: "archivebox.fill")
                                        .tint(.orange)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    cartaoParaExcluir = cartao
                                    
                                    Task{
                                        let existe = try await LancamentoRepository().existeLancamentoParaCartao(
                                            cartaoUuid: cartao.uuid)
                                        
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
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
        .overlay(
            Group {
                if cartoesFiltrados.isEmpty {
                    Text("Nenhum Cartão")
                        .font(.title3)
                        .fontWeight(.bold)    
                        .multilineTextAlignment(.center)
                }
            }
        )
        .navigationTitle("Cartões")
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top) {
            Picker("Filtro", selection: $filtroSelecionado) {
                ForEach(FiltroCartao.allCases) { filtro in
                    Text(filtro.titulo).tag(filtro)
                }
            }
            .pickerStyle(.segmented)
            .padding()
        }
        .alert("", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Este cartão está um uso e não poderá ser excluído.")
        }
        .alert("Excluir Cartão?", isPresented: $mostrarConfirmacao) {
            Button("Excluir", role: .destructive) {
                Task{
                    if let cartao = cartaoParaExcluir {
                        await viewModel.remover(cartao)
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Essa ação não poderá ser desfeita.")
        }
        .sheet(isPresented: $mostrarNovoCartao) {
            NavigationStack {
                if viewModel.cartoes.isEmpty || sub.isSubscribed {
                    NovoCartaoView()
                } else {
                    PaywallView()
                }
            }
        }
        .ifAvailableSearchable(searchText: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { // Use .navigationBarTrailing para iOS 16
                Button {
                    mostrarNovoCartao = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            if #available(iOS 26, *) {
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
        }
    }
}
    


// MARK: - Row

struct CartaoRow: View {

    let cartao: CartaoModel

    var body: some View {
        HStack(spacing: 12) {
            Image(cartao.operadoraEnum.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            VStack (alignment: .leading){
                Text(cartao.nome)
                    .font(.body)
                Text(cartao.conta?.nome ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Detalhe do Cartão

struct CartaoDetalheView: View {

    let cartao: CartaoModel
    @State private var mostrarEdicao = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(cartao.operadoraEnum.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    Text(cartao.nome)
                        .font(.title2.bold())
                }
            }
            
            Section(header: Text("Informações do Cartão")) {
                HStack {
                    Text("Operadora")
                    Spacer()
                    Text(cartao.operadoraEnum.nome)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Conta")
                    Spacer()
                    Text(cartao.conta?.nome ?? "")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Detalhes Financeiros")) {
                HStack {
                    Text("Dia do Vencimento")
                    Spacer()
                    Text("\(cartao.vencimento)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Dia do Fechamento")
                    Spacer()
                    Text("\(cartao.fechamento)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Limite")
                    Spacer()
                    Text(cartao.limite, format: .currency(code: cartao.conta?.currencyCode ?? Locale.systemCurrencyCode))
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Detalhar Cartão")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarEdicao = true
                } label: {
                    Text("Editar")
                }
            }
        }
        .sheet(isPresented: $mostrarEdicao) {
            EditarCartaoView(cartao: cartao)
        }
    }
}

// MARK: - Novo Cartão

enum NovoCartaoSheet: Identifiable {
    case conta
    case operadora

    var id: Int { hashValue }
}

private enum CampoFoco {
    case nome
    case vencimento
    case fechamento
    case limite
}

struct NovoCartaoView: View {
   
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovoCartaoViewModel()
    @State private var sheetAtivo: NovoCartaoSheet?
    @State private var erroValidacao: CartaoValidacaoErro?
    @FocusState private var campoFocado: CampoFoco?

    var body: some View {
        Form {
            Section{
                TextField("Nome", text: $viewModel.nome)
                    .focused($campoFocado, equals: .nome)
                        .submitLabel(.next)
                        .textInputAutocapitalization(.words)
                        .onSubmit {
                            campoFocado = .vencimento
                        }
                Button {
                    sheetAtivo = .operadora
                } label: {
                    HStack {
                        Text("Operadora")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(viewModel.operadora?.nome ?? "Selecione")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.footnote)
                    }
                }
                
                Button {
                    sheetAtivo = .conta
                } label: {
                    HStack {
                        Text("Conta")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(viewModel.conta?.nome ?? String(localized: "Selecione"))
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
            }
            Section{
                TextField("Dia do Vencimento", text: $viewModel.vencimentoTexto)
                    .keyboardType(.numberPad)
                    .focused($campoFocado, equals: .vencimento)
                
                TextField("Dia do Fechamento", text: $viewModel.fechamentoTexto)
                    .keyboardType(.numberPad)
                    .focused($campoFocado, equals: .fechamento)
                
                TextField("Limite", text: $viewModel.limiteTexto)
                    .keyboardType(.decimalPad)
                    .focused($campoFocado, equals: .limite)
            }
            
        }
        .navigationTitle("Novo Cartão")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheetAtivo) { sheet in
            NavigationStack {
                switch sheet {
                case .conta:
                    ZoomContaView(
                        contaSelecionada: $viewModel.conta
                    )
                    
                case .operadora:
                    ZoomOperadoraView(
                        operadoraSelecionada: $viewModel.operadora
                    )
                }
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
                        await salvar()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(!viewModel.formValido)
            }
        }
        .alert(item: $erroValidacao) { erro in
            Alert(
                title: Text("Erro"),
                message: Text(erro.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                campoFocado = .nome
            }
        }
    }

    private func salvar() async {
        do {
            let cartao = try viewModel.construirCartao()
            try await CartaoRepository().salvar(cartao)
            dismiss()
        } catch let erro as CartaoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao salvar cartão", error)
        }
    }
}

#Preview {
    NovoCartaoView()
}


// MARK: - Editar Cartão

struct EditarCartaoView: View {
    
    @State var cartao: CartaoModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovoCartaoViewModel()
    @State private var sheetAtivo: NovoCartaoSheet?
    @State private var erroValidacao: CartaoValidacaoErro?

    var body: some View {
        NavigationStack {
            Form {
                Section{
                    TextField("Nome", text: $viewModel.nome)
                        .textInputAutocapitalization(.words)
                    
                    Button {
                        sheetAtivo = .operadora
                    } label: {
                        HStack {
                            Text("Operadora")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(viewModel.operadora?.nome ?? "Selecione")
                                                            .foregroundColor(.secondary)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                    
                    Button {
                        sheetAtivo = .conta
                    } label: {
                        HStack {
                            Text("Conta")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(viewModel.conta?.nome ?? "Selecione")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                }
                Section{
                    TextField("Dia do Vencimento", text: $viewModel.vencimentoTexto)
                        .keyboardType(.numberPad)

                    TextField("Dia do Fechamento", text: $viewModel.fechamentoTexto)
                        .keyboardType(.numberPad)

                    TextField("Limite", text: $viewModel.limiteTexto)
                                            .keyboardType(.decimalPad)
                }
                
            }
            .navigationTitle("Editar Cartão")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheetAtivo) { sheet in
                NavigationStack {
                    switch sheet {
                    case .conta:
                        ZoomContaView(
                            contaSelecionada: $viewModel.conta
                        )
                        
                    case .operadora:
                        ZoomOperadoraView(
                            operadoraSelecionada: $viewModel.operadora
                        )
                    }
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
                            await salvar()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(!viewModel.formValido)
                }
            }
            .alert(item: $erroValidacao) { erro in
                Alert(
                    title: Text("Erro"),
                    message: Text(erro.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear(){               
                viewModel.nome = cartao.nome
                viewModel.operadora = cartao.operadoraEnum
                viewModel.conta = cartao.conta
                viewModel.vencimentoTexto = cartao.vencimento.description
                viewModel.fechamentoTexto = cartao.fechamento.description
                viewModel.setLimite(cartao.limite)
            }
        }
    }

    private func salvar() async {
        do {
            var cartao = try viewModel.construirCartao()
            cartao.id = self.cartao.id
            cartao.uuid = self.cartao.uuid
            
            try await CartaoRepository().editar(cartao)
            let pagamentoPadrao: MeioPagamento? = UserDefaults.standard.carregarPagamentoPadrao()
            
            if pagamentoPadrao?.contaModel?.uuid == cartao.uuid {
                let meio = MeioPagamento.cartao(cartao)
                UserDefaults.standard.salvarPagamentoPadrao(meio)
            }
            
            dismiss()
        } catch let erro as CartaoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao editar cartão", error)
        }
    }
}

