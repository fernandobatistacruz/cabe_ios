import SwiftUI

struct CartaoCredito: Identifiable, Hashable {
    let id = UUID()
    var nome: String
    var operadora: String
    var contaPagamento: String
    var vencimento: Int
    var fechamento: Int
    var limite: Double
}

struct CartoesListView: View {
    
    @State private var searchText = ""
    @State private var mostrarNovoCartao = false
    
    @State private var cartoes: [CartaoCredito] = [
        CartaoCredito(
            nome: "Visa Gold",
            operadora: "Visa",
            contaPagamento: "Conta Corrente",
            vencimento: 10,
            fechamento: 5,
            limite: 5000
        ),
        CartaoCredito(
            nome: "Master Platinum",
            operadora: "Mastercard",
            contaPagamento: "Poupança",
            vencimento: 15,
            fechamento: 10,
            limite: 12000
        )
    ]
    
    var cartoesFiltrados: [CartaoCredito] {
        searchText.isEmpty
        ? cartoes
        : cartoes.filter {
            $0.nome.localizedCaseInsensitiveContains(searchText) ||
            $0.operadora.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(cartoesFiltrados) { cartao in
            NavigationLink {
                CartaoDetalheView(cartao: cartao)
            } label: {
                CartaoRow(cartao: cartao)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Cartões")       
        .toolbar(.hidden, for: .tabBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Buscar"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarNovoCartao = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarNovoCartao) {
            NovoCartaoView { novo in
                cartoes.append(novo)
            }
        }
    }
}

struct CartaoRow: View {

    let cartao: CartaoCredito

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text(cartao.nome)
                Text(cartao.operadora)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(cartao.limite, format: .currency(code: "BRL"))
                .foregroundStyle(.gray)
        }
    }
}

// MARK: - Detalhe

struct CartaoDetalheView: View {

    let cartao: CartaoCredito
    @State private var mostrarEdicao = false

    var body: some View {
        Form {

            Section("Cartão") {
                InfoRow(label: "Nome", value: cartao.nome)
                InfoRow(label: "Operadora", value: cartao.operadora)
                InfoRow(label: "Conta de pagamento", value: cartao.contaPagamento)
            }

            Section("Fatura") {
                InfoRow(label: "Fechamento", value: "Dia \(cartao.fechamento)")
                InfoRow(label: "Vencimento", value: "Dia \(cartao.vencimento)")
            }

            Section("Limite") {
                InfoRow(
                    label: "Limite total",
                    value: cartao.limite.formatted(.currency(code: "BRL"))
                )
            }
        }
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
            NavigationStack {
                EditarCartaoView(cartao: cartao)
            }
        }
    }
}

// MARK: - Novo Cartão

struct NovoCartaoView: View {

    @Environment(\.dismiss) private var dismiss
    let onSave: (CartaoCredito) -> Void

    @State private var nome = ""
    @State private var operadora = ""
    @State private var contaPagamento = ""
    @State private var vencimento = ""
    @State private var fechamento = ""
    @State private var limite = ""

    var body: some View {
        NavigationStack {
            Form {
                
                Section("Cartão") {
                    TextField("Nome", text: $nome)
                    TextField("Operadora", text: $operadora)
                }
                
                Section("Pagamento") {
                    TextField("Conta de pagamento", text: $contaPagamento)
                }
                
                Section("Fatura") {
                    TextField("Dia de fechamento", text: $fechamento)
                        .keyboardType(.numberPad)
                    
                    TextField("Dia de vencimento", text: $vencimento)
                        .keyboardType(.numberPad)
                }
                
                Section("Limite") {
                    TextField("Limite total", text: $limite)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Novo Cartão")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "xmark")
                        .onTapGesture { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "checkmark")
                        .onTapGesture { salvar() }
                        .opacity(nome.isEmpty ? 0.4 : 1)
                }
            }
        }
    }

    private func salvar() {
        onSave(
            CartaoCredito(
                nome: nome,
                operadora: operadora,
                contaPagamento: contaPagamento,
                vencimento: Int(vencimento) ?? 1,
                fechamento: Int(fechamento) ?? 1,
                limite: Double(limite.replacingOccurrences(of: ",", with: ".")) ?? 0
            )
        )
        dismiss()
    }
}

// MARK: - Editar Cartão (TODOS OS CAMPOS)

struct EditarCartaoView: View {

    @Environment(\.dismiss) private var dismiss
    let cartao: CartaoCredito

    @State private var nome = ""
    @State private var operadora = ""
    @State private var contaPagamento = ""
    @State private var vencimento = ""
    @State private var fechamento = ""
    @State private var limite = ""

    var body: some View {
        Form {

            Section("Cartão") {
                TextField("Nome", text: $nome)
                TextField("Operadora", text: $operadora)
            }

            Section("Pagamento") {
                TextField("Conta de pagamento", text: $contaPagamento)
            }

            Section("Fatura") {
                TextField("Dia de fechamento", text: $fechamento)
                    .keyboardType(.numberPad)

                TextField("Dia de vencimento", text: $vencimento)
                    .keyboardType(.numberPad)
            }

            Section("Limite") {
                TextField("Limite total", text: $limite)
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("Editar Cartão")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "xmark")
                    .onTapGesture { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "checkmark")
                    .onTapGesture {
                        // aqui futuramente você atualiza a lista
                        dismiss()
                    }
                    .opacity(nome.isEmpty ? 0.4 : 1)
            }
        }
        .onAppear {
            nome = cartao.nome
            operadora = cartao.operadora
            contaPagamento = cartao.contaPagamento
            vencimento = String(cartao.vencimento)
            fechamento = String(cartao.fechamento)
            limite = String(cartao.limite)
        }
    }
}

// MARK: - Helper

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    CartoesListView().environmentObject(ThemeManager())
}

