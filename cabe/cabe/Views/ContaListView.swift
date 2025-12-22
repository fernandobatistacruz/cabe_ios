import SwiftUI
import GRDB
internal import Combine

struct ContaListView: View {

    @State private var searchText = ""
    @State private var mostrarNovaConta = false
    @State private var mostrarConfirmacao = false
    @State private var contaParaExcluir: ContaModel?

    @StateObject private var viewModel: ContaListViewModel

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
                        Text("Nenhuma conta encontrada")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            )
        .toolbar(.hidden, for: .tabBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Buscar"
        )
        .alert(
            "Excluir conta?",
            isPresented: $mostrarConfirmacao,          
        )
        {
            Button("Excluir", role: .destructive) {
                if let conta = contaParaExcluir {
                    excluir(conta)
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
                    mostrarNovaConta = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarNovaConta) {
            NovaContaView()
        }
    }
    
    private func excluir(_ conta: ContaModel) {
        do {
            try ContaRepository()
                .remover(id: conta.id ?? 0, uuid: conta.uuid)
        }catch{
            debugPrint("Erro ao remover conta", error)
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
            Image(systemName: "creditcard")
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
                Image(systemName: "creditcard")
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
        .navigationTitle("Detalhar Conta")
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
            EditarContaView(conta: conta)
        }
    }
}

// MARK: - Nova Conta


struct NovaContaView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var nome: String = ""
    @State private var saldoText: String = ""
    @State private var saldoDecimal: Decimal? = nil


    var body: some View {
        NavigationStack {
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
                TextField("Nome da conta", text: $nome)
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

    private func salvar() {
        
        conta.nome = nome
        conta.saldo = NSDecimalNumber(decimal: saldoDecimal ?? 0).doubleValue
        
        do {
            try ContaRepository().editar(conta)
        }
        catch{
            debugPrint("Erro ao editar conta", error)
        }
        
        dismiss()
    }
}


// MARK: - Preview

/*
#Preview {
    struct MockRepo: ContaDAO {
        func listar() throws -> [ContaModel] { [
            ContaModel(nome: "Nubank", saldo: 1200),
            ContaModel(nome: "Inter", saldo: -50)
        ] }
    }
    NavigationStack {
        ContasListView(repository: MockRepo())
            .preferredColorScheme(.light)
    }
}
 */


