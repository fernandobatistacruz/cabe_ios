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
    @State private var selectedDate: Date = Date()
    
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
                List {
                    ForEach(lancamentosAgrupados, id: \.date) { section in
                        
                        Section {
                            ForEach(section.items) { item in
                                switch item {
                                case .simples(let lancamento):
                                    NavigationLink {
                                        LancamentoDetalheView(lancamento: lancamento)
                                    } label: {
                                        LancamentoRow(lancamento: lancamento)
                                    }
                                    
                                case .cartaoAgrupado(let cartao, let total, let lancamentos):
                                    NavigationLink {
                                        CartaoFaturaView(
                                            cartao: cartao,
                                            lancamentos: lancamentos,
                                            total: total,
                                            vencimento: section.date
                                        )
                                    } label: {
                                        CartaoAgrupadoRow(
                                            cartao: cartao,
                                            lancamentos: lancamentos,
                                            total: total
                                        )
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
                        } header: {
                            Text(section.date, format: .dateTime.day().month(.wide))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                // ➕ FAB (continua igual)
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
                Text(selectedDate, format: .dateTime.month(.wide))
            )
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Buscar")
            
            // 🔹 TOOLBAR
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "chevron.left")
                        Text(selectedDate, format: .dateTime.year())
                    }
                }
                
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
                CalendarioZoomView(selectedDate: $selectedDate)
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
    let total: Decimal
    let vencimento: Date
    
    @State private var searchText = ""
    
    var filtroLancamentos: [LancamentoModel] {
        searchText.isEmpty
        ? lancamentos
        : lancamentos
            .filter {
                $0.descricao.localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        List {
            HStack(spacing: 16) {
                Image(cartao.operadoraEnum.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cartao.nome)
                        .font(.title3.bold())
                    Text(vencimento.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(
                    total,
                    format: .currency(code: cartao.conta?.currencyCode ?? "BRL")
                )
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            }
            if(!filtroLancamentos.isEmpty){
                Section("Entries") {
                    ForEach(filtroLancamentos) { lancamento in
                        NavigationLink {
                            LancamentoDetalheView(lancamento: lancamento)
                        } label: {
                            LancamentoRow(lancamento: lancamento)
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
        .navigationTitle("Fatura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Buscar", text: $searchText)
                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .clipShape(Capsule())
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button{
                    print("Filtro")
                    
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                Menu {
                    Button {
                        print("Ação")
                    } label: {
                        Label("Conferência de Fatura", systemImage: "doc.text.magnifyingglass")
                    }
                    Button {
                        print("Ação")
                    } label: {
                        Label("Exportar Fatura", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .overlay(
            Group {
                if filtroLancamentos.isEmpty {
                    Text("Nenhum lançamento encontrado")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        )
    }
}

struct CartaoAgrupadoRow: View {

    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]
    let total: Decimal

    var body: some View {
        HStack {
            Image(cartao.operadoraEnum.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cartao.nome)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text("Fatura")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(
                total,
                format: .currency(code: cartao.conta?.currencyCode ?? "BRL")
            )
            .foregroundColor(.secondary)
        }
    }
}


// MARK: - Row

struct LancamentoRow: View {

    let lancamento: LancamentoModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: lancamento.categoria?.getIcone().systemName ?? "")
                .foregroundColor(lancamento.categoria?.getCor().cor)


            VStack(alignment: .leading) {
                Text(lancamento.descricao)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(lancamento.categoria?.nome ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
            Text(
                lancamento.valor,
                format:
                        .currency(
                            code: lancamento.cartao?.conta?.currencyCode ?? "BRL"
                        )
            )
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
                    Image(systemName: lancamento.categoria?.getIcone().systemName ?? "",)
                        .foregroundColor(lancamento.categoria?.getCor().cor)
                        .font(.system(size: 30))
                    VStack (alignment: .leading){
                        Text(lancamento.descricao)
                            .font(.title2.bold())
                        Text(lancamento.categoria?.nome ?? "")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(
                        lancamento.valor,
                        format: .currency(code: lancamento.conta?.currencyCode ?? "BRL")
                    )
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            Section(header: Text("Geral")) {
                HStack {
                    HStack {
                        Text("Situação")
                        Spacer()
                        Text(lancamento.pago ? String(localized: "Sim") : String(localized: "Não"))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    HStack {
                        Text("Repete")
                        Spacer()
                        Text("Fixo")
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    HStack {
                        Text("Pago Com")
                        Spacer()
                        Text("Fixo")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if (lancamento.cartao != nil){
                Section(header: Text("Cartão de Crédito")) {
                    HStack {
                        Text("Fatura")
                        Spacer()
                        Text("\(lancamento.descricao)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cartão")
                        Spacer()
                        Text("\(lancamento.cartao?.nome ?? "")")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Data da Compra")
                        Spacer()
                        Text(lancamento.descricao)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            
            if (lancamento.dividido){
                Section(header: Text("Dividida")) {
                    HStack {
                        Text("Dividida")
                        Spacer()
                        Text(lancamento.dividido ? String(localized: "Sim") : String(localized: "Não"))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Valor")
                        Spacer()
                        Text("\(lancamento.valor/2)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Anotação")) {
                HStack {
                    Text(lancamento.anotacao).lineLimit(5)
                }
            }
            
        }
        .navigationTitle("Detalhar Lançamento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
    case categoria
    case pagamento
    case fatura

    var id: Int { hashValue }
}

struct NovoLancamentoView: View {
   
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = NovoLancamentoViewModel()
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?
    @State private var mostrarCalendario = false
    @State private var mostrarZoomCategoria = false
    @State private var showCalendar = false
    @State private var selectedFatura = Date()
   
    var body: some View {
        NavigationStack{
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Tipo", selection: $vm.tipo) {
                        ForEach(Tipo.allCases.reversed(), id: \.self) { tipo in
                            Text(tipo.descricao).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Form {
                        Section{
                            TextField("Descrição", text: $vm.descricao)
                            Button {
                                sheetAtivo = .categoria
                            } label: {
                                HStack {
                                    Text("Categoria")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(
                                        vm.categoria?.nome ?? String(
                                            localized: "Nenhuma"
                                        )
                                    )
                                    .foregroundColor(.secondary)
                                    .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                        }
                        Section{
                            Button {
                                sheetAtivo = .pagamento
                            } label: {
                                HStack {
                                    Text("Pagamento")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(vm.meioPagamentoSelecionado?.titulo ??  String(
                                        localized: "Nenhuma")
                                    ).foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                            Button {
                                sheetAtivo = .fatura
                            } label: {
                                HStack {
                                    Text("Fatura")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(
                                        selectedFatura.formatted(
                                            .dateTime
                                                .month(.wide)
                                                .year()
                                        )
                                    )
                                    .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                            
                            if(vm.tipo == .despesa){
                                Toggle(isOn: $vm.dividida) {Text("Dividida")}
                            }
                            
                            /* Quando precisar filtar a que aparece no menu
                             
                             var opcoesDisponiveis: [TipoRecorrente] {
                                 if formaPagamento == .cartao {
                                     return TipoRecorrente.allCases
                                 } else {
                                     return TipoRecorrente.allCases.filter { $0 != .parcelado }
                                 }
                             }
                             
                             Picker("Recorrência", selection: $tipoRecorrente) {
                                 ForEach(opcoesDisponiveis) { item in
                                     Text(item.titulo)
                                         .tag(item)
                                 }
                             }
                             .pickerStyle(.menu)
                             .tint(.secondary)
                             
                             */
                            
                            HStack {
                                Picker("Repete", selection: $vm.tipoRecorrente) {
                                    ForEach(TipoRecorrente.allCases) { item in
                                        Text(item.titulo)
                                            .tag(item)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.secondary)
                            }
                            
                            TextField("Valor", text: $vm.limiteTexto)
                                .keyboardType(.decimalPad)
                            
                            Toggle(isOn: $vm.pago) {Text("Pago")}
                            
                            Button {
                                mostrarCalendario.toggle()
                            } label: {
                                HStack {
                                    Text("Data da Compra")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(vm.dataSelecionada.formatted(date: .abbreviated, time: .omitted))")
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 22)
                                                .fill(
                                                    Color(
                                                        uiColor: .secondarySystemFill
                                                    )
                                                )
                                        )
                                }
                            }
                            
                            if mostrarCalendario {
                                DatePicker(
                                    "",
                                    selection: $vm.dataSelecionada,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                            }
                            
                        }
                        Section{
                            ZStack(alignment: .topLeading) {
                                if vm.anotacao.isEmpty {
                                    Text("Anotação")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                }
                                TextEditor(text: $vm.anotacao)
                                    .padding(8)
                                    .background(Color.clear)
                            }
                            .frame(minHeight: 80, maxHeight: 100)
                        }
                    }
                }
            }
            .navigationTitle("Nova")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheetAtivo) { sheet in
                NavigationStack {
                    switch sheet {
                    case .categoria:
                        CategoriaZoomView(
                            categoriaSelecionada: $vm.categoria,
                            tipo: vm.tipo
                        )
                    case .pagamento:
                        ZoomPagamentoView(selecionado: $vm.meioPagamentoSelecionado)
                    case .fatura:
                        CalendarioZoomView(
                            selectedDate: $selectedFatura
                        )
                        .presentationDetents([.medium, .large])
                        
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
                    .disabled(!vm.formValido)
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
        if vm.tipo == .despesa {
            do {
                var lancamento = try vm.construirLancamento()
                try LancamentoRepository().salvar(&lancamento)
                dismiss()
            } catch let erro as LancamentoValidacaoErro {
                erroValidacao = erro
            } catch {
                debugPrint("Erro inesperado ao salvar lançamento", error)
            }
        } else {
            //Salvar Receita
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
    @State public var selectedYear = Calendar.current.component(.year, from: Date())
    @State public var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var faturaData = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section{
                    TextField("Nome", text: $viewModel.descricao)
                    Button {
                        sheetAtivo = .categoria
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
                        sheetAtivo = .categoria
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
                    case .categoria:
                        CategoriaZoomView(
                            categoriaSelecionada: $viewModel.categoria,
                            tipo: viewModel.tipo
                        )
                    case .pagamento:
                        OperadoraZoomView(
                            operadoraSelecionada: $viewModel.operadora
                        )
                    case .fatura:
                        CalendarioZoomView(selectedDate: $faturaData)
                            .presentationDetents([.medium,.large])
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
                viewModel.descricao = lancamento.descricao
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



