import SwiftUI
import GRDB
import Combine

struct ContaListView: View {

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var mostrarNovaConta = false
    @State private var mostrarConfirmacao = false
    @State private var contaParaExcluir: ContaModel?
    @EnvironmentObject var sub: SubscriptionManager
    @StateObject private var viewModel: ContaListViewModel
    @State private var mostrarTransferencia = false

    init() {
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
                ContaDetalheView(conta: conta)
            } label: {
                ContaRow(conta: conta)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            contaParaExcluir = conta
                            mostrarConfirmacao = true
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Contas")
        .overlay(
            Group {
                if contasFiltradas.isEmpty {                   
                    Text("Nenhuma Conta")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
            }
        )
        .toolbar(.hidden, for: .tabBar)
        .alert(
            "Excluir Conta?",
            isPresented: $mostrarConfirmacao,
        )
        {
            Button("Excluir", role: .destructive) {
                Task{
                    if let conta = contaParaExcluir {
                       await viewModel.remover(conta)
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        }
        message: {
            Text("Essa ação não poderá ser desfeita.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarTransferencia = true
                } label: {
                    Label("Transferência", systemImage: "arrow.left.arrow.right")
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
            Image(systemName: "building.columns.fill")
                .foregroundStyle(iconColor)
                .font(.system(size: 18, weight: .medium))

            Text(conta.nome)
                .font(.body)

            Spacer()

            Text(conta.saldo, format: .currency(code: conta.currencyCode))
                .foregroundStyle(.gray)
               
        }
    }
}

// MARK: - Detalhe da Conta

struct ContaDetalheView: View {

    let conta: ContaModel
    @State private var mostrarEdicao = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(conta.saldo >= 0 ? .green : .red)

                Text(conta.nome)
                    .font(.title2.bold())

                Text(conta.saldo, format: .currency(code: conta.currencyCode))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Detalhar Conta")
        .background(Color(.systemGroupedBackground))        
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
    @State private var saldoDecimal: Decimal? = nil
    @FocusState private var campoFocado: CampoFoco?


    var body: some View {
        Form {
            TextField("Nome", text: $nome)
                .focused($campoFocado, equals: .nome)
                    .submitLabel(.next)
                    .onSubmit {
                        campoFocado = .saldo
                    }
            
            TextField("Saldo", text: $saldoText)
                .keyboardType(.decimalPad)
                .focused($campoFocado, equals: .saldo)
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
                    Task{
                        await salvar()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(nome.isEmpty || saldoDecimal == nil)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                campoFocado = .nome
            }
        }
    }
    

    private func salvar() async {
        
        let conta = ContaModel.init(
            uuid: UUID().uuidString,
            nome: nome,
            saldo: NSDecimalNumber(decimal: saldoDecimal ?? 0).doubleValue,
            currencyCode : Locale.current.currency?.identifier ?? Locale.systemCurrencyCode
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
    @State private var saldoDecimal: Decimal? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome da Conta", text: $nome)
                TextField("Saldo", text: $saldoText)
                    .keyboardType(.decimalPad)
                    .onChange(of: saldoText) { value in
                        saldoDecimal = NumberFormatter.decimalInput
                            .number(from: value) as? Decimal
                    }
            }
            .navigationTitle("Editar Conta")
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
                        Task{
                           await salvar()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(nome.isEmpty || saldoDecimal == nil)
                }
            }
            .onAppear {
                nome = conta.nome
                let formatter = NumberFormatter.decimalInput
                saldoText = formatter.string(
                    from: NSDecimalNumber(value: conta.saldo)
                ) ?? ""
                saldoDecimal = NSDecimalNumber(value: conta.saldo).decimalValue
            }
        }
    }

    private func salvar() async {
        
        conta.nome = nome
        conta.saldo = NSDecimalNumber(decimal: saldoDecimal ?? 0).doubleValue
        
        do {
            try await ContaRepository().editar(conta)
        }
        catch{
            debugPrint("Erro ao editar conta", error)
        }
        
        dismiss()
    }
}


// MARK: - Preview
