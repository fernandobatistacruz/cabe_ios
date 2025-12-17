import SwiftUI

// MARK: - Model

struct Conta: Identifiable, Hashable {
    let id = UUID()
    var nome: String
    var saldo: Double
}

// MARK: - Lista de Contas

struct ContasListView: View {

    @State private var searchText = ""
    @State private var mostrarNovaConta = false

    @State private var contas: [Conta] = [
        Conta(nome: "Conta Corrente", saldo: 1250.50),
        Conta(nome: "Poupança", saldo: 8200.00),
        Conta(nome: "Carteira", saldo: 320.75)
    ]

    var contasFiltradas: [Conta] {
        searchText.isEmpty
        ? contas
        : contas.filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(contasFiltradas) { conta in
            NavigationLink {
                ContaDetalheView(conta: conta)
            }
            label:{
                ContaRow(conta: conta)
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

    let conta: Conta

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
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Detalhe da Conta

struct ContaDetalheView: View {

    let conta: Conta
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
    @State private var saldo: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome da conta", text: $nome)

                TextField("Saldo inicial", text: $saldo)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Nova Conta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // ❌ Cancelar
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                // ✔️ Salvar
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        salvar()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(nome.isEmpty)
                }
            }
        }
    }

    private func salvar() {
        // Aqui futuramente você cria a conta e devolve para a lista
        dismiss()
    }
}


// MARK: - Editar Conta

struct EditarContaView: View {

    @Environment(\.dismiss) private var dismiss

    let conta: Conta

    @State private var nome: String = ""
    @State private var saldo: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome da conta", text: $nome)

                TextField("Saldo", text: $saldo)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Editar Conta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // ❌ Cancelar
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                // ✔️ Salvar
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        salvar()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(nome.isEmpty)
                }
            }
            .onAppear {
                nome = conta.nome
                saldo = String(conta.saldo)
            }
        }
    }

    private func salvar() {
        // Aqui futuramente você atualiza a conta
        dismiss()
    }
}


// MARK: - Preview

#Preview {
    ContasListView()
        .preferredColorScheme(.light)
}

