import SwiftUI

// MARK: - Model

struct Conta: Identifiable, Hashable {
    let id = UUID()
    var nome: String
    var saldo: Double
    var icon: String
    var color: Color
}

// MARK: - Lista de Contas

struct ContasListView: View {

    @State private var searchText = ""
    @State private var mostrarNovaConta = false

    @State private var contas: [Conta] = [
        Conta(nome: "Conta Corrente", saldo: 1250.50, icon: "creditcard", color: .blue),
        Conta(nome: "Poupança", saldo: 8200, icon: "banknote", color: .green),
        Conta(nome: "Carteira", saldo: 320.75, icon: "wallet.pass", color: .orange)
    ]

    var contasFiltradas: [Conta] {
        searchText.isEmpty
        ? contas
        : contas.filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(contasFiltradas) { conta in
                NavigationLink(value: conta) {
                    ContaRow(conta: conta)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Contas")
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
            .navigationDestination(for: Conta.self) { conta in
                ContaDetalheView(conta: conta)
            }
            .sheet(isPresented: $mostrarNovaConta) {
                NovaContaView()
            }
        }
    }
}

// MARK: - Row (ícone simples)

struct ContaRow: View {

    let conta: Conta

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: conta.icon)
                .foregroundStyle(conta.color)
                .font(.system(size: 20, weight: .medium))

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
                Image(systemName: conta.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(conta.color)

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

// MARK: - Nova Conta (placeholder)

struct NovaContaView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Nova Conta")
                .navigationTitle("Adicionar")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Editar Conta (placeholder)

struct EditarContaView: View {
    @Environment(\.dismiss) private var dismiss
    let conta: Conta

    var body: some View {
        NavigationStack {
            Text("Editar \(conta.nome)")
                .navigationTitle("Editar Conta")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Salvar") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    ContasListView()
        .preferredColorScheme(.dark)
}

