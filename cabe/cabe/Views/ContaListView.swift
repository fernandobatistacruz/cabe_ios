import SwiftUI
import GRDB
import Combine

struct ContaListView: View {

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var mostrarNovaConta = false
    @State private var mostrarConfirmacao = false
    @State private var mostrarAlerta = false
    @State private var contaParaExcluir: ContaModel?
    @EnvironmentObject var sub: SubscriptionManager
    @StateObject private var viewModel: ContaListViewModel
    @State private var mostrarTransferencia = false
    @ObservedObject var vmLancamentos: LancamentoListViewModel

    init(vmLancamentos: LancamentoListViewModel) {
        self.vmLancamentos = vmLancamentos
        
        let repository = ContaRepository()
        _viewModel = StateObject(
            wrappedValue: ContaListViewModel(repository: repository)
        )
    }
    
    var contasFiltradas: [ContaModel] {
        searchText.isEmpty
        ? viewModel.contas
        : viewModel.contas
            .filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(contasFiltradas) { conta in
            NavigationLink {
                ContaDetalheView(conta: conta, vmLancamentos: vmLancamentos)
            } label: {
                ContaRow(conta: conta)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            contaParaExcluir = conta
                            
                            Task {
                                let existeLancamento = try await LancamentoRepository()
                                    .existeLancamentoParaConta(contaUuid: conta.uuid)
                                
                                let existeCartao = try await CartaoRepository()
                                    .existeCartaoParaConta(contaUuid: conta.uuid)
                                
                                if existeLancamento || existeCartao {
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
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Contas")
        .background(Color(.systemGroupedBackground))
        .scrollContentBackground(.hidden)
        .overlay(
            Group {
                if contasFiltradas.isEmpty {                   
                    Text("Nenhuma Conta")
                        .font(.title3)
                        .fontWeight(.bold)                       
                        .multilineTextAlignment(.center)
                }
            }
        )
        .toolbar(.hidden, for: .tabBar)
        .alert("", isPresented: $mostrarAlerta) {
           Button("OK", role: .cancel) {}
        } message: {
            Text("Esta conta está um uso e não poderá ser excluída.")
        }
        .alert(
            "Deseja excluir essa conta?",
            isPresented: $mostrarConfirmacao,
        )
        {
            Button("Confirmar", role: .destructive) {
                Task{
                    if let conta = contaParaExcluir {
                       await viewModel.remover(conta)
                    }
                }
            }
        }       
        .ifAvailableSearchable(searchText: $searchText)
        .toolbar {
            if #available(iOS 26, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarTransferencia = true
                    } label: {
                        Label("Transferência", systemImage: "arrow.left.arrow.right")
                    }
                }
            }
            else {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        mostrarTransferencia = true
                    } label: {
                        Label("Transferência", systemImage: "arrow.left.arrow.right")
                    }
                    
                    Button {
                        mostrarNovaConta = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
                    if searchText.isEmpty {
                        Spacer()
                        Button {
                            mostrarNovaConta = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $mostrarNovaConta) {
            NavigationStack {
                if viewModel.contas.isEmpty || sub.isSubscribed {
                    NovaContaView()
                } else {
                    PaywallView()
                }
            }
        }
        .sheet(isPresented: $mostrarTransferencia) {
            NavigationStack {
                TransferenciaView()
            }
        }
    }
}

// MARK: - Row

struct ContaRow: View {

    let conta: ContaModel

    private var iconColor: Color {
        conta.saldo >= 0 ? .green : .red
    }

    var body: some View {
        HStack(spacing: 12) {
            
            LogoBancoView(codigo: conta.logo)

            Text(conta.nome)
                .font(.body)

            Spacer()

            Text(conta.saldo, format: .currency(code: conta.currencyCode))
                .foregroundStyle(.gray)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
               
        }
    }
}

// MARK: - Detalhe da Conta

struct ContaDetalheView: View {

    let conta: ContaModel
    @State private var mostrarEdicao = false
    @ObservedObject var vmLancamentos: LancamentoListViewModel

    init(conta: ContaModel, vmLancamentos: LancamentoListViewModel) {
        self.conta = conta
        self.vmLancamentos = vmLancamentos
    }

    // MARK: - Filtro

    private var lancamentosFiltrados: [LancamentoModel] {
        vmLancamentos.lancamentos.filter {
            $0.contaUuid == conta.uuid ||
            $0.cartao?.contaUuid == conta.uuid
        }
    }

    // MARK: - View

    var body: some View {
        List {
            HStack(spacing: 10) {
                LogoBancoView(codigo: conta.logo)

                VStack(alignment: .leading, spacing: 4) {
                    Text(conta.nome)
                        .font(.title3.bold())
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(conta.saldoFormatado)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: true, vertical: false)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            .padding(.vertical, 4)
            
            if !lancamentosFiltrados.isEmpty {
                Section("Lançamentos") {
                    ForEach(lancamentosFiltrados) { lancamento in
                        NavigationLink {
                            LancamentoDetalheView(
                                lancamento: lancamento,
                                vmLancamentos: vmLancamentos
                            )
                        } label: {
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,
                                mostrarVencimento: true
                            )
                        }
                        .listRowInsets(
                            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalhar Conta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    mostrarEdicao = true
                }
            }
        }
        .sheet(isPresented: $mostrarEdicao) {
            EditarContaView(conta: conta)
        }
    }
}

// MARK: - Nova Conta

private enum CampoFoco {
    case nome
    case saldo
}

struct NovaContaView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var nome: String = ""
    @State private var saldoText: String = ""
    @State private var saldoDecimal: Decimal = 0
    @FocusState private var campoFocado: CampoFoco?
    @State private var logo: Int = 0
    @State private var mostrarSelecaoIcone = false


    var body: some View {
        Form {
            TextField("Nome", text: $nome)
                .focused($campoFocado, equals: .nome)
                    .submitLabel(.next)
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        campoFocado = .saldo
                    }
            
            Button {
                mostrarSelecaoIcone = true
            } label: {
                HStack(spacing: 12) {
                    Text("Ícone")
                        .foregroundColor(.primary)
                    Spacer()
                    LogoBancoView(codigo: logo)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
                
            }
            
            TextField("Saldo", text: $saldoText)
                .keyboardType(.numberPad)
                .focused($campoFocado, equals: .saldo)
                .onChange(of: saldoText) { novoValor in
                    atualizarValor(novoValor)
                }
            
        }
        .navigationTitle("Nova Conta")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $mostrarSelecaoIcone) {
            SelecaoIconeModalView(logo: $logo)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
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
                .disabled(nome.isEmpty || saldoText.isEmpty)
            }
        }
        .task {
            await Task.yield()
            campoFocado = .nome
        }
    }
    
    func atualizarValor(_ novoTexto: String) {
        // remove tudo que não for número
        let numeros = novoTexto.filter { $0.isNumber }

        let centavos = Decimal(Int(numeros) ?? 0)
        let valorDecimal = centavos / 100

        saldoDecimal = valorDecimal

        let formatter = CurrencyFormatter.formatter(currencyCode: Locale.systemCurrencyCode)
        saldoText = formatter.string(from: saldoDecimal as NSDecimalNumber) ?? ""
    }

    private func salvar() async {
        
        let conta = ContaModel.init(
            uuid: UUID().uuidString,
            nome: nome,
            saldo: saldoDecimal,
            currencyCode : Locale.current.currency?.identifier ?? Locale.systemCurrencyCode,
            logo: logo
        )
        
        do {
            try await ContaRepository().salvar(conta)
        }
        catch{
            debugPrint("Erro ao editar conta", error)
        }
        
        dismiss()
    }
}


// MARK: - Editar Conta

struct EditarContaView: View {

    @Environment(\.dismiss) private var dismiss

    @State var conta: ContaModel

    @State private var nome: String = ""
    @State private var saldoText: String = ""
    @State private var saldoDecimal: Decimal = 0
    @State private var logo: Int = 0
    @State private var mostrarSelecaoIcone = false
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $nome)
                    .textInputAutocapitalization(.words)
                
                Button {
                    mostrarSelecaoIcone = true
                } label: {
                    HStack(spacing: 12) {
                        Text("Ícone")
                            .foregroundColor(.primary)
                        Spacer()
                        LogoBancoView(codigo: logo)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.footnote)
                    }
                    
                }
                
                TextField("Saldo", text: $saldoText)
                    .keyboardType(.numberPad)
                    .onChange(of: saldoText) { novoValor in
                        atualizarValor(novoValor)
                    }
            }
            .navigationTitle("Editar Conta")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $mostrarSelecaoIcone) {
                SelecaoIconeModalView(logo: $logo)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
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
                    .disabled(nome.isEmpty || saldoText.isEmpty)
                }
            }
            .onAppear {
                saldoDecimal = conta.saldo
                nome = conta.nome
                let formatter = CurrencyFormatter.formatter(currencyCode: conta.currencyCode)
                saldoText = formatter.string(from: conta.saldo as NSDecimalNumber) ?? ""
                logo = conta.logo
            }
        }
    }
    
    func atualizarValor(_ novoTexto: String) {
        // remove tudo que não for número
        let numeros = novoTexto.filter { $0.isNumber }

        let centavos = Decimal(Int(numeros) ?? 0)
        let valorDecimal = centavos / 100

        saldoDecimal = valorDecimal

        let formatter = CurrencyFormatter.formatter(currencyCode: conta.currencyCode)
        saldoText = formatter.string(from: saldoDecimal as NSDecimalNumber) ?? ""
    }

    private func salvar() async {
        
        conta.nome = nome
        conta.saldo = saldoDecimal
        conta.logo = logo
        
        do {
            try await ContaRepository().editar(conta)
            
            let pagamentoPadrao: MeioPagamento? = UserDefaults.standard.carregarPagamentoPadrao()
            
            if pagamentoPadrao?.contaModel?.uuid == conta.uuid {
                let meio = MeioPagamento.conta(conta)               
                UserDefaults.standard.salvarPagamentoPadrao(meio)
            }
        }
        catch{
            debugPrint("Erro ao editar conta", error)
        }
        
        dismiss()
    }
}

// MARK: - Modal de Seleção de Ícones (Grade com Zoom)
struct SelecaoIconeModalView: View {
    @Binding var logo: Int
    @Environment(\.dismiss) private var dismiss
    
    // Configuração de 3 colunas flexíveis para a grade
    private let colunas = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: colunas, spacing: 20) {                   
                    ForEach(BancoLogo.allCases) { banco in
                        CartaoIconeView(
                            isSelecionado: logo == banco.rawValue,
                            acao: { selecionar(banco.rawValue) }
                        ) {
                            Image(banco.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Escolha o Ícone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
    
    private func selecionar(_ novoCodigo: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            logo = novoCodigo
        }
        dismiss()
    }
}

// MARK: - Componentes Auxiliares de UI
struct CartaoIconeView<Content: View>: View {
    let isSelecionado: Bool
    let acao: () -> Void
    let content: () -> Content
    
    var body: some View {
        Button(action: acao) {
            VStack {
                content()
            }
            .frame(width: 80, height: 80)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isSelecionado ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            .scaleEffect(isSelecionado ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct IconeBancoView: View {
    let logo: Int?
    let tamanho: CGFloat
    
    var body: some View {
        if let codigo = logo, let banco = BancoLogo(rawValue: codigo) {
            Image(banco.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: tamanho, height: tamanho)
        } else {
            Image(systemName: "building.columns.fill")
                .resizable()
                .scaledToFit()
                .frame(width: tamanho, height: tamanho)
                .foregroundColor(.blue)
        }
    }
}


// MARK: - Preview
