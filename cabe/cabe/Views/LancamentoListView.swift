//
//  LancamentoListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//


import SwiftUI
import GRDB
internal import Combine

struct LancamentoListView: View {

    @State private var searchText = ""
    @State private var mostrarNovoLancamento = false
    @State private var mostrarConfirmacao = false
    @State private var lancamentoParaExcluir: LancamentoModel?
    @StateObject private var viewModel: LancamentoListViewModel
    @State private var showCalendar = false

    @State public var selectedYear = Calendar.current.component(.year, from: Date())
    @State public var selectedMonth = Calendar.current.component(.month, from: Date())
    private var chaveMes: String {
        "\(selectedYear)-\(selectedMonth)"
    }

    init() {
        let repository = LancamentoRepository()
        _viewModel = StateObject(
            wrappedValue: LancamentoListViewModel(repository: repository)
        )
    }

    // MARK: - Filtro
    var lancamentosFiltrados: [LancamentoModel] {
        let texto = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return viewModel.lancamentos }

        return viewModel.lancamentos.filter {
            $0.descricao.localizedCaseInsensitiveContains(texto)
        }
    }

    // MARK: - View
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {

                        ForEach(lancamentosAgrupados, id: \.date) { section in

                            // 📅 Header da data
                            Text(section.date, format: .dateTime.day().month(.wide))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.bottom, 6)

                            // 📦 Card do dia
                            VStack(spacing: 0) {
                                ForEach(section.items) { item in
                                    VStack(spacing: 0) {

                                        switch item {

                                        case .simples(let lancamento):
                                            NavigationLink {
                                                LancamentoDetalheView(lancamento: lancamento)
                                            } label: {
                                                LancamentoRow(lancamento: lancamento)
                                                    .padding(12)
                                            }

                                        case .cartaoAgrupado(let cartao, let total, let lancamentos):
                                            NavigationLink {
                                                CartaoFaturaView(
                                                    cartao: cartao,
                                                    lancamentos: lancamentos
                                                )
                                            } label: {
                                                CartaoAgrupadoRow(
                                                    cartao: cartao,
                                                    total: total
                                                )
                                                .padding(12)
                                            }
                                        }

                                        if item.id != section.items.last?.id {
                                            Divider()
                                                .padding(.leading, 44)
                                        }
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                            )
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 80)
                    }
                }
                .id(chaveMes)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: chaveMes)


                // ➕ FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            mostrarNovoLancamento = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(
                Calendar.current.monthSymbols[selectedMonth - 1].capitalized
            )
            .animation(.easeInOut(duration: 0.2), value: selectedMonth)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Buscar")

            // 🔹 TOOLBAR
            .toolbar {

                // 📅 Calendário (leading)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "chevron.left")
                        Text(selectedYear, format: .number.grouping(.never))
                    }
                }

                // ⋯ Menu (trailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("Mais ações")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }

            // 🔹 SHEETS
            .sheet(isPresented: $mostrarNovoLancamento) {
                NovoLancamentoView()
            }
            .sheet(isPresented: $showCalendar) {
                MonthYearPickerView(
                    initialYear: selectedYear,
                    initialMonth: selectedMonth
                ) { newYear, newMonth in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedYear = newYear
                        selectedMonth = newMonth
                    }
                }
                .presentationDetents([.medium, .large])
            }

        }
    }


    // MARK: - Agrupamento
    var lancamentosAgrupados: [(date: Date, items: [LancamentoItem])] {

        let porData = Dictionary(grouping: lancamentosFiltrados) {
            Calendar.current.startOfDay(for: $0.dataAgrupamento)
        }

        let resultado = porData.map { (date, lancamentosDoDia) in

            let itensSimples = lancamentosDoDia
                .filter { $0.cartao == nil }
                .map { LancamentoItem.simples($0) }

            let comCartao = lancamentosDoDia.filter { $0.cartao != nil }

            let porCartao = Dictionary(grouping: comCartao) {
                $0.cartao!.id!
            }

            let itensCartao = porCartao.map { (_, lancamentos) in
                let cartao = lancamentos.first!.cartao!
                let total = lancamentos.reduce(Decimal.zero) {
                    $0 + Decimal($1.valor)
                }

                return LancamentoItem.cartaoAgrupado(
                    cartao: cartao,
                    total: total,
                    lancamentos: lancamentos
                )
            }

            return (date: date, items: itensSimples + itensCartao)
        }

        return resultado.sorted { $0.date > $1.date }
    }

    // MARK: - Excluir
    private func excluir(_ lancamento: LancamentoModel) {
        do {
            try LancamentoRepository()
                .remover(id: lancamento.id ?? 0, uuid: lancamento.uuid)
        } catch {
            debugPrint("Erro ao remover lançamento", error)
        }
    }
}


struct LancamentoCartaoItem: Identifiable {
    let id: Int64               // id do cartão
    let cartao: CartaoModel
    let total: Decimal
    let lancamentos: [LancamentoModel]
}


struct LancamentoCartaoRow: View {
    let item: LancamentoCartaoItem

    var body: some View {
        HStack(spacing: 12) {

            // Ícone do cartão
            Image(systemName: "creditcard")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.cartao.nome)
                    .font(.headline)

                Text("\(item.lancamentos.count) lançamentos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.total, format: .currency(code: "BRL"))
                .font(.headline)

            // Chevron manual
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .contentShape(Rectangle()) // garante tap em toda a row
    }
}

struct CartaoFaturaView: View {
    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {

                // 📌 Cabeçalho do cartão
                VStack(alignment: .leading, spacing: 8) {
                    Text(cartao.nome)
                        .font(.largeTitle)
                        .bold()

                    Text("Vencimento dia \(cartao.vencimento)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // 📌 Lista de lançamentos do cartão
                LazyVStack(spacing: 8) {
                    ForEach(lancamentos) { lancamento in
                        LancamentoRow(lancamento: lancamento)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Cartão")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct CartaoAgrupadoRow: View {

    let cartao: CartaoModel
    let total: Decimal

    var body: some View {
        HStack {
            Image(systemName: "creditcard")
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(cartao.nome)
                    .font(.body)
                    .foregroundColor(.primary)

                Text("Fatura do cartão")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(
                total,
                format: .currency(code: cartao.conta?.currencyCode ?? "BRL")
            )
            .font(.body.weight(.semibold))
            .foregroundColor(.secondary)
        }
    }
}


// MARK: - Row

struct LancamentoRow: View {

    let lancamento: LancamentoModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(lancamento.descricao)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(lancamento.categoria?.nome ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }
}



// MARK: - Detalhe do Cartão

struct LancamentoDetalheView: View {

    let lancamento: LancamentoModel
    @State private var mostrarEdicao = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "creditcard")
                    Text(lancamento.descricao)
                        .font(.title2.bold())
                }
            }
            
            Section(header: Text("Informações do Cartão")) {
                HStack {
                    Text("Operadora")
                    Spacer()
                    Text(lancamento.descricao)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Conta")
                    Spacer()
                    Text(lancamento.descricao)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Detalhes Financeiros")) {
                HStack {
                    Text("Dia de Vencimento")
                    Spacer()
                    Text("\(lancamento.descricao)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Dia de Fechamento")
                    Spacer()
                    Text("\(lancamento.descricao)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Limite")
                    Spacer()
                    Text(
                        lancamento.valor,
                        format:
                                .currency(
                                    code: lancamento.conta?.currencyCode ?? "BRL"
                                )
                    )
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Detalhar Lançamento")
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
            EditarLancamentoView(lancamento: lancamento)
        }
    }
}

// MARK: - Novo Cartão

enum NovoLancamentoSheet: Identifiable {
    case conta
    case operadora

    var id: Int { hashValue }
}

struct NovoLancamentoView: View {
   
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovoLancamentoViewModel()
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?

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
                            Text(viewModel.operadora?.nome ?? String(localized: "Nenhuma"))
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
                            Text(viewModel.conta?.nome ?? String(localized: "Nenhuma"))
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
            .navigationTitle("Novo Cartão")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheetAtivo) { sheet in
                NavigationStack {
                    switch sheet {
                    case .conta:
                        ContaZoomView(
                            contaSelecionada: $viewModel.conta
                        )
                        
                    case .operadora:
                        OperadoraZoomView(
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
                        salvar()
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
    }

    private func salvar() {
        do {
            var lancamento = try viewModel.construirLancamento()
            try LancamentoRepository().salvar(&lancamento)
            dismiss()
        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao salvar lançamento", error)
        }
    }
}

#Preview {
    NovoLancamentoView()
}


// MARK: - Editar Cartão

struct EditarLancamentoView: View {
    
    @State var lancamento: LancamentoModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovoLancamentoViewModel()
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?

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
                        ContaZoomView(
                            contaSelecionada: $viewModel.conta
                        )
                        
                    case .operadora:
                        OperadoraZoomView(
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
                        salvar()
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
                viewModel.nome = lancamento.descricao
                viewModel.setLimite(lancamento.valor)
            }
        }
    }

    private func salvar() {
        do {
            var lancamento = try viewModel.construirLancamento()
            lancamento.id = self.lancamento.id
            lancamento.uuid = self.lancamento.uuid
            
            try LancamentoRepository().editar(lancamento)
            dismiss()
        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao editar lançamento", error)
        }
    }
}

