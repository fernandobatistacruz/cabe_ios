import SwiftUI
import GRDB
internal import Combine

import GRDB
import SwiftUI


@MainActor
final class ContaRepositorio: ObservableObject {

    @Published private(set) var contas: [ContaModel] = []

    private let repository: ContaRepositoryProtocol
    private var cancellable: AnyDatabaseCancellable?

    init(repository: ContaRepositoryProtocol) {
        self.repository = repository
        observar()
    }

    private func observar() {
        cancellable = repository.observeContas { [weak self] contas in
            self?.contas = contas
        }
    }
}

struct ContasListView: View {

    @State private var searchText = ""
    @State private var mostrarNovaConta = false

    @StateObject private var contaRepsitorio = ContaRepositorio(
        repository: ContaRepository(
            dbQueue: AppDatabase.shared.dbQueue
        )
    )

    
    var contasFiltradas: [ContaModel] {
        searchText.isEmpty
        ? contaRepsitorio.contas
        : contaRepsitorio.contas
            .filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(contasFiltradas) { conta in
            NavigationLink {
                ContaDetalheView(conta: conta)
            } label: {
                ContaRow(conta: conta)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            do {
                                try ContaDAO()
                                    .remover(id: conta.id ?? 0, uuid: conta.uuid)
                            }catch{
                                debugPrint("Erro ao remover conta", error)
                            }
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
            }
        }        
        .listStyle(.insetGrouped)
        .navigationTitle("Contas")
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $searchText, prompt: "Pesquisar")
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

            Text(conta.saldo, format: .currency(code: "BRL"))
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

                Text(conta.saldo, format: .currency(code: "BRL"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detalhes")
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
    @State private var saldo: Double? = nil

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome da conta", text: $nome)

                TextField("Saldo", value: $saldo, format: .number)
                    .keyboardType(.decimalPad)
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
                    .disabled(nome.isEmpty || saldo == nil)
                }
            }
        }
    }

    private func salvar() {
        var conta = ContaModel.init(
            uuid: UUID().uuidString,
            nome: nome,
            saldo: saldo ?? 0.0,
        )
        
        do {
            try ContaDAO().salvar(&conta)
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
    @State private var saldo: Double? = nil

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome da conta", text: $nome)

                TextField("Saldo", value: $saldo, format: .number)
                    .keyboardType(.decimalPad)
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
                    .disabled(nome.isEmpty || saldo == nil)
                }
            }
            .onAppear {
                nome = conta.nome
                saldo = conta.saldo
            }
        }
    }

    private func salvar() {
        
        conta.nome = nome
        conta.saldo = saldo ?? 0.0
        
        do {
            try ContaDAO().editar(conta)
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

