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
    @State private var mostrarNovoCartao = false
    @State private var mostrarConfirmacao = false
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
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Picker("Filtro", selection: $filtroSelecionado) {
                    ForEach(FiltroCartao.allCases) { filtro in
                        Text(filtro.titulo).tag(filtro)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    Section {
                        ForEach(cartoesFiltrados) { cartao in
                            NavigationLink(
                                destination: CartaoDetalheView(cartao: cartao)
                            ) {
                                CartaoRow(cartao: cartao)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            cartaoParaExcluir = cartao
                                            mostrarConfirmacao = true
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
                .scrollContentBackground(.hidden)
                .overlay(
                    Group {
                        if cartoesFiltrados.isEmpty {
                            Text("Nenhum cartão")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                )
            }
        }
        .navigationTitle("Cartões")
        .toolbar(.hidden, for: .tabBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Buscar"
        )
        .alert("Excluir cartão?", isPresented: $mostrarConfirmacao) {
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { // Use .navigationBarTrailing para iOS 16
                Button {
                    mostrarNovoCartao = true
                } label: {
                    Image(systemName: "plus")
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
                    Text("Dia de Vencimento")
                    Spacer()
                    Text("\(cartao.vencimento)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Dia de Fechamento")
                    Spacer()
                    Text("\(cartao.fechamento)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Limite")
                    Spacer()
                    Text(cartao.limite, format: .currency(code: cartao.conta?.currencyCode ?? "BRL"))
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Detalhar Cartão")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "pencil")
                    .onTapGesture {
                        mostrarEdicao = true
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

struct NovoCartaoView: View {
   
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovoCartaoViewModel()
    @State private var sheetAtivo: NovoCartaoSheet?
    @State private var erroValidacao: CartaoValidacaoErro?

    var body: some View {
        Form {
            Section{
                TextField("Nome", text: $viewModel.nome)
                Button {
                    sheetAtivo = .operadora
                } label: {
                    HStack {
                        Text("Operadora")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(viewModel.operadora?.nome ?? String(localized: "Nenhuma"))
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
                        Text(viewModel.conta?.nome ?? String(localized: "Nenhuma"))
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
                
                TextField("Dia do Fechamento", text: $viewModel.fechamentoTexto)
                    .keyboardType(.numberPad)
                
                TextField("Limite", text: $viewModel.limiteTexto)
                    .keyboardType(.decimalPad)
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
                    Button {
                        sheetAtivo = .operadora
                    } label: {
                        HStack {
                            Text("Operadora")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(viewModel.operadora?.nome ?? "Nenhuma")
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
                            Text(viewModel.conta?.nome ?? "Nenhuma")
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
            dismiss()
        } catch let erro as CartaoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao editar cartão", error)
        }
    }
}

